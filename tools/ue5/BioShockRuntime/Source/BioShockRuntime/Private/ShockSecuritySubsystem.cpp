#include "ShockSecuritySubsystem.h"

#include "BaseShockAI.h"
#include "CollisionQueryParams.h"
#include "Engine/Engine.h"
#include "EngineUtils.h"
#include "Engine/World.h"
#include "NavigationSystem.h"
#include "ShockPlayer.h"
#include "ShockSecurityBot.h"
#include "ShockSecurityCamera.h"
#include "ShockSecurityDevice.h"

UShockSecuritySubsystem* UShockSecuritySubsystem::Get(const UWorld* World)
{
	return World ? World->GetSubsystem<UShockSecuritySubsystem>() : nullptr;
}

UShockSecuritySubsystem* UShockSecuritySubsystem::GetForWorld(UObject* WorldContextObject)
{
	if (!GEngine || !WorldContextObject)
	{
		return nullptr;
	}
	UWorld* World = GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::ReturnNull);
	return Get(World);
}

void UShockSecuritySubsystem::PurgeInvalidBots()
{
	ActiveBots.RemoveAll([](const AShockSecurityBot* Bot) { return !IsValid(Bot); });
}

void UShockSecuritySubsystem::RegisterBot(AShockSecurityBot* Bot)
{
	if (!Bot)
	{
		return;
	}
	PurgeInvalidBots();
	ActiveBots.AddUnique(Bot);
}

void UShockSecuritySubsystem::UnregisterBot(AShockSecurityBot* Bot)
{
	ActiveBots.Remove(Bot);
}

void UShockSecuritySubsystem::NotifyBotKilled(AShockSecurityBot* Bot)
{
	if (!Bot)
	{
		return;
	}
	UnregisterBot(Bot);
	UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_BOT_DESPAWN label=%s reason=killed"), *Bot->GetScriptLabel().ToString());
}

bool UShockSecuritySubsystem::IsPathNodeCandidate(const AActor* Actor) const
{
	if (!Actor)
	{
		return false;
	}
	for (const FName& Tag : Actor->Tags)
	{
		const FString TagStr = Tag.ToString();
		if (TagStr.Contains(TEXT("PathNode"), ESearchCase::IgnoreCase)
			|| TagStr.Contains(TEXT("FlyingPathNode"), ESearchCase::IgnoreCase))
		{
			return true;
		}
	}
#if WITH_EDITOR
	const FString Label = Actor->GetActorLabel();
	if (Label.Contains(TEXT("PathNode"), ESearchCase::IgnoreCase)
		|| Label.Contains(TEXT("FlyingPathNode"), ESearchCase::IgnoreCase)
		|| Label.StartsWith(TEXT("BotSpawnMarker"), ESearchCase::IgnoreCase))
	{
		return true;
	}
#endif
	return false;
}

bool UShockSecuritySubsystem::HasLineOfSightToPoint(UWorld* World, FVector From, FVector To) const
{
	if (!World)
	{
		return true;
	}
	FHitResult Hit;
	FCollisionQueryParams Params(SCENE_QUERY_STAT(ShockBotSpawnLOS), false);
	const bool bHit = World->LineTraceSingleByChannel(Hit, From, To, ECC_Visibility, Params);
	return !bHit;
}

FVector UShockSecuritySubsystem::ResolveSpawnLocation(UWorld* World, FVector NearLocation) const
{
	return ResolveSpawnLocation(World, NearLocation, bAlarmVersusAI);
}

FVector UShockSecuritySubsystem::ResolveSpawnLocation(
	UWorld* World,
	FVector PlayerLocation,
	bool bVersusAI) const
{
	if (World && !NextSpawnLocationLabel.IsNone())
	{
		const FString Want = NextSpawnLocationLabel.ToString();
		for (TActorIterator<AActor> It(World); It; ++It)
		{
			AActor* Actor = *It;
			if (!Actor)
			{
				continue;
			}
#if WITH_EDITOR
			if (Actor->GetActorLabel().Equals(Want, ESearchCase::CaseSensitive))
			{
				return Actor->GetActorLocation();
			}
#endif
			if (Actor->GetFName() == NextSpawnLocationLabel
				|| Actor->GetName().Equals(Want, ESearchCase::CaseSensitive))
			{
				return Actor->GetActorLocation();
			}
		}
	}

	const float MinDist = bVersusAI ? 1500.0f : 3000.0f;
	const float MaxDist = bVersusAI ? 4000.0f : 6000.0f;
	const FVector Eye = PlayerLocation + FVector(0.0f, 0.0f, 64.0f);

	TArray<FVector> Candidates;
	if (World)
	{
		for (TActorIterator<AActor> It(World); It; ++It)
		{
			AActor* Actor = *It;
			if (!IsPathNodeCandidate(Actor))
			{
				continue;
			}
			const FVector Loc = Actor->GetActorLocation();
			const float Dist = FVector::Dist(PlayerLocation, Loc);
			if (Dist < MinDist || Dist > MaxDist)
			{
				continue;
			}
			// Out of sight: LOS must FAIL (blocked or no clear view).
			if (HasLineOfSightToPoint(World, Eye, Loc + FVector(0.0f, 0.0f, 40.0f)))
			{
				continue;
			}
			Candidates.Add(Loc);
		}

		if (Candidates.Num() == 0)
		{
			if (UNavigationSystemV1* Nav = UNavigationSystemV1::GetCurrent(World))
			{
				for (int32 Attempt = 0; Attempt < 24; ++Attempt)
				{
					const float Radius = FMath::FRandRange(MinDist, MaxDist);
					FNavLocation NavLoc;
					if (!Nav->GetRandomReachablePointInRadius(PlayerLocation, Radius, NavLoc))
					{
						continue;
					}
					const float Dist = FVector::Dist(PlayerLocation, NavLoc.Location);
					if (Dist < MinDist || Dist > MaxDist)
					{
						continue;
					}
					if (HasLineOfSightToPoint(World, Eye, NavLoc.Location + FVector(0.0f, 0.0f, 40.0f)))
					{
						continue;
					}
					Candidates.Add(NavLoc.Location);
					break;
				}
			}
		}
	}

	if (Candidates.Num() > 0)
	{
		return Candidates[FMath::RandRange(0, Candidates.Num() - 1)];
	}

	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_BOT_SPAWN_FALLBACK reason=no_out_of_sight_point band=%.0f-%.0f vsAI=%d"),
		MinDist,
		MaxDist,
		bAlarmVersusAI ? 1 : 0);
	return PlayerLocation + FVector(250.0f, 0.0f, 0.0f);
}

AShockSecurityBot* UShockSecuritySubsystem::SpawnBotForVerify(FVector Location, AShockPlayer* Player)
{
	AShockSecurityBot* Result = nullptr;
	const int32 Before = ActiveBots.Num();
	if (SpawnBotsNear(Location, 1, Player) > 0 && ActiveBots.Num() > Before)
	{
		Result = ActiveBots.Last();
	}
	return Result;
}

int32 UShockSecuritySubsystem::SpawnBotsNear(FVector NearLocation, int32 Count, AShockPlayer* Player)
{
	UWorld* World = GetWorld();
	if (!World || Count <= 0)
	{
		return 0;
	}

	PurgeInvalidBots();
	const FVector PlayerLoc = Player ? Player->GetActorLocation() : NearLocation;
	int32 Spawned = 0;
	for (int32 Attempt = 0; Attempt < Count && ActiveBots.Num() < MaxActiveBots; ++Attempt)
	{
		const FVector SpawnLoc =
			ResolveSpawnLocation(World, PlayerLoc, bAlarmVersusAI)
			+ FVector(0.0f, Attempt * 120.0f, 0.0f);
		FActorSpawnParameters Params;
		Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
		AShockSecurityBot* Bot = World->SpawnActor<AShockSecurityBot>(
			AShockSecurityBot::StaticClass(),
			SpawnLoc,
			FRotator::ZeroRotator,
			Params);
		if (!Bot)
		{
			continue;
		}

		const FString Label = FString::Printf(TEXT("SecurityBot_%d"), NextBotIndex++);
		Bot->ConfigureIdentity(FName(TEXT("SecurityBot")), FName(*Label));
#if WITH_EDITOR
		Bot->SetActorLabel(Label);
#endif
		Bot->ActivateForPlayer(Player);
		RegisterBot(Bot);
		++Spawned;
		UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_BOT_SPAWN label=%s"), *Label);
	}

	if (!NextSpawnLocationLabel.IsNone())
	{
		NextSpawnLocationLabel = NAME_None;
	}

	BotDespawnRemaining = -1.0f;
	return Spawned;
}

void UShockSecuritySubsystem::OnAlarmStateChanged(
	AShockPlayer* Player,
	bool bOn,
	bool bWasOn,
	FName SourceLabel)
{
	if (!Player)
	{
		return;
	}

	if (bOn)
	{
		bAlarmVersusAI = false;
		if (UWorld* World = GetWorld())
		{
			if (!SourceLabel.IsNone())
			{
				for (TActorIterator<ABaseShockAI> It(World); It; ++It)
				{
					ABaseShockAI* AI = *It;
					if (!AI || Cast<AShockSecurityBot>(AI))
					{
						continue;
					}
					if (AI->GetScriptLabel() == SourceLabel)
					{
						bAlarmVersusAI = true;
						break;
					}
#if WITH_EDITOR
					if (AI->GetActorLabel().Equals(SourceLabel.ToString(), ESearchCase::CaseSensitive))
					{
						bAlarmVersusAI = true;
						break;
					}
#endif
				}
			}
		}

		FVector Near = Player->GetActorLocation();
		if (UWorld* World = GetWorld())
		{
			if (AShockSecurityCamera* Camera = Cast<AShockSecurityCamera>(
					AShockSecurityDevice::FindByLabel(World, SourceLabel)))
			{
				Near = Camera->GetActorLocation();
				(void)Near; // distance band is always player-relative; Near kept for legacy callers
			}
		}

		if (!bWasOn)
		{
			AlarmRemainingSeconds = AlarmDurationSeconds;
			AlarmPlayer = Player;

			const int32 Want = PendingBotSpawnCount > 0 ? PendingBotSpawnCount : 1;
			PendingBotSpawnCount = 0;
			SpawnBotsNear(Player->GetActorLocation(), Want, Player);
			return;
		}

		// Second alarm while one runs: add one bot (guide ch.32), up to MaxActiveBots.
		SpawnBotsNear(Player->GetActorLocation(), 1, Player);
		return;
	}

	if (!bOn && bWasOn)
	{
		AlarmRemainingSeconds = -1.0f;
		AlarmPlayer = nullptr;
		bAlarmVersusAI = false;
		ScheduleBotDespawn(BotLifetimeAfterAlarmClearSeconds);
	}
}

void UShockSecuritySubsystem::OnCameraAlert(AShockSecurityCamera* Camera)
{
	if (!Camera)
	{
		return;
	}

	UWorld* World = GetWorld();
	if (!World)
	{
		return;
	}

	AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World);
	if (!Player)
	{
		return;
	}

	if (Camera->GetAllegiance() == EShockDeviceAllegiance::Hostile)
	{
		const FName Label = Camera->DeviceLabel.IsNone() ? Camera->GetFName() : Camera->DeviceLabel;
		if (!Player->IsSecurityAlarmOn())
		{
			PendingBotSpawnCount = FMath::Max(PendingBotSpawnCount, Camera->NumSecurityBotsSpawned);
			Player->SetSecurityAlarmOn(true, Label);
		}
		else
		{
			SpawnBotsNear(Camera->GetActorLocation(), Camera->NumSecurityBotsSpawned, Player);
		}
	}
}

void UShockSecuritySubsystem::ScheduleBotDespawn(float DelaySeconds)
{
	// Negative = never (default). Zero = immediate. Positive = delayed.
	if (DelaySeconds < 0.0f)
	{
		BotDespawnRemaining = -1.0f;
		return;
	}
	if (DelaySeconds == 0.0f)
	{
		DespawnAllBots();
		return;
	}
	BotDespawnRemaining = DelaySeconds;
}

void UShockSecuritySubsystem::TickBotDespawn(float DeltaSeconds)
{
	if (BotDespawnRemaining < 0.0f)
	{
		return;
	}

	BotDespawnRemaining -= DeltaSeconds;
	if (BotDespawnRemaining <= 0.0f)
	{
		BotDespawnRemaining = -1.0f;
		DespawnAllBots();
	}
}

void UShockSecuritySubsystem::DespawnAllBots()
{
	PurgeInvalidBots();
	for (AShockSecurityBot* Bot : ActiveBots)
	{
		if (!Bot)
		{
			continue;
		}
		UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_BOT_DESPAWN label=%s reason=alarm_clear"), *Bot->GetScriptLabel().ToString());
		Bot->Destroy();
	}
	ActiveBots.Reset();
	BotDespawnRemaining = -1.0f;
}

void UShockSecuritySubsystem::ApplySecurityShutdown(float Duration)
{
	if (Duration <= 0.0f)
	{
		return;
	}

	PurgeInvalidBots();
	for (AShockSecurityBot* Bot : ActiveBots)
	{
		if (Bot)
		{
			Bot->ApplySecurityShutdown(Duration);
		}
	}
}

bool UShockSecuritySubsystem::ActivateBotByLabel(FName BotLabel, FName OwnerLabel)
{
	(void)OwnerLabel;
	UWorld* World = GetWorld();
	if (!World || BotLabel.IsNone())
	{
		return false;
	}

	for (TActorIterator<AShockSecurityBot> It(World); It; ++It)
	{
		AShockSecurityBot* Bot = *It;
		if (!Bot)
		{
			continue;
		}
		if (Bot->GetScriptLabel() == BotLabel)
		{
			Bot->SetDormant(false);
			Bot->SetBotAllegiance(EShockDeviceAllegiance::Hostile);
			if (AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World))
			{
				Bot->ActivateForPlayer(Player);
			}
			RegisterBot(Bot);
			return true;
		}
#if WITH_EDITOR
		if (Bot->GetActorLabel().Equals(BotLabel.ToString(), ESearchCase::CaseSensitive))
		{
			Bot->SetDormant(false);
			Bot->SetBotAllegiance(EShockDeviceAllegiance::Hostile);
			if (AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World))
			{
				Bot->ActivateForPlayer(Player);
			}
			RegisterBot(Bot);
			return true;
		}
#endif
	}
	return false;
}

bool UShockSecuritySubsystem::CommandBotsAttackTarget(FName AttackeeLabel)
{
	if (AttackeeLabel.IsNone())
	{
		return false;
	}

	PurgeInvalidBots();
	bool bAny = false;
	for (AShockSecurityBot* Bot : ActiveBots)
	{
		if (Bot && Bot->IsBotOperationalForVerify())
		{
			Bot->CommandAttackLabel(AttackeeLabel);
			bAny = true;
		}
	}
	return bAny;
}

int32 UShockSecuritySubsystem::GetActiveBotCountForVerify() const
{
	int32 Count = 0;
	for (const AShockSecurityBot* Bot : ActiveBots)
	{
		if (IsValid(Bot) && Bot->IsBotOperationalForVerify())
		{
			++Count;
		}
	}
	return Count;
}

void UShockSecuritySubsystem::AdvanceSecurity(float DeltaSeconds)
{
	if (DeltaSeconds <= 0.0f)
	{
		return;
	}

	TickBotDespawn(DeltaSeconds);

	if (AlarmRemainingSeconds >= 0.0f)
	{
		AlarmRemainingSeconds -= DeltaSeconds;
		if (AlarmRemainingSeconds <= 0.0f)
		{
			AlarmRemainingSeconds = -1.0f;
			if (AShockPlayer* Player = AlarmPlayer.Get())
			{
				Player->SetSecurityAlarmOn(false, NAME_None);
			}
			AlarmPlayer = nullptr;
		}
	}
}

void UShockSecuritySubsystem::AdvanceSecurityForVerify(float DeltaSeconds)
{
	if (DeltaSeconds <= 0.0f)
	{
		return;
	}

	AdvanceSecurity(DeltaSeconds);

	PurgeInvalidBots();
	for (AShockSecurityBot* Bot : ActiveBots)
	{
		if (Bot)
		{
			Bot->AdvanceBotForVerify(DeltaSeconds);
		}
	}
}

void UShockSecuritySubsystem::TickSecurity(float DeltaSeconds)
{
	AdvanceSecurity(DeltaSeconds);
}
