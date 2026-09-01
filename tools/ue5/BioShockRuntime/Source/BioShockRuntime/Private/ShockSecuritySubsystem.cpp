#include "ShockSecuritySubsystem.h"

#include "Engine/Engine.h"
#include "EngineUtils.h"
#include "Engine/World.h"
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

FVector UShockSecuritySubsystem::ResolveSpawnLocation(UWorld* World, FVector NearLocation) const
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
		}
	}

	return NearLocation + FVector(250.0f, 0.0f, 0.0f);
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
	int32 Spawned = 0;
	for (int32 Attempt = 0; Attempt < Count && ActiveBots.Num() < MaxActiveBots; ++Attempt)
	{
		const FVector SpawnLoc = ResolveSpawnLocation(World, NearLocation) + FVector(0.0f, Attempt * 120.0f, 0.0f);
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
	(void)SourceLabel;
	if (!Player)
	{
		return;
	}

	if (bOn && !bWasOn)
	{
		const int32 Want = PendingBotSpawnCount > 0 ? PendingBotSpawnCount : 1;
		PendingBotSpawnCount = 0;
		FVector Near = Player->GetActorLocation();
		if (UWorld* World = GetWorld())
		{
			if (AShockSecurityCamera* Camera = Cast<AShockSecurityCamera>(
					AShockSecurityDevice::FindByLabel(World, SourceLabel)))
			{
				Near = Camera->GetActorLocation();
			}
		}
		SpawnBotsNear(Near, Want, Player);
		return;
	}

	if (!bOn && bWasOn)
	{
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
	if (DelaySeconds <= 0.0f)
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

void UShockSecuritySubsystem::AdvanceSecurityForVerify(float DeltaSeconds)
{
	if (DeltaSeconds <= 0.0f)
	{
		return;
	}

	TickBotDespawn(DeltaSeconds);

	PurgeInvalidBots();
	for (AShockSecurityBot* Bot : ActiveBots)
	{
		if (Bot)
		{
			Bot->AdvanceBotForVerify(DeltaSeconds);
		}
	}
}
