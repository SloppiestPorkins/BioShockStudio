#include "ShockGameMode.h"
#include "BaseShockAI.h"
#include "ShockAiArchetype.h"
#include "ShockAmmoPickup.h"
#include "ShockDeathRespawnHandler.h"
#include "ShockHudWidget.h"
#include "ShockPhysicsLibrary.h"
#include "ShockPlayer.h"
#include "ShockWeapon.h"

#include "Camera/CameraComponent.h"
#include "CollisionQueryParams.h"
#include "Components/CapsuleComponent.h"
#include "Components/SkeletalMeshComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/DirectionalLight.h"
#include "Engine/SkeletalMesh.h"
#include "Engine/SkyLight.h"
#include "Engine/StaticMeshActor.h"
#include "Engine/World.h"
#include "TimerManager.h"
#include "GameFramework/WorldSettings.h"
#include "Components/LightComponent.h"
#include "Components/SkyLightComponent.h"
#include "EngineUtils.h"
#include "GameFramework/Character.h"
#include "GameFramework/PlayerController.h"
#include "GameFramework/PlayerStart.h"
#include "HAL/PlatformMisc.h"
#include "Misc/CommandLine.h"

namespace
{
FRotator PlayableStartRotation(const AActor* Start)
{
	FRotator Look = Start ? Start->GetActorRotation() : FRotator::ZeroRotator;
	// Python unreal.Rotator(0, 90, 0) is roll/pitch/yaw, so possess prep stored pitch=90.
	if (FMath::IsNearlyZero(Look.Yaw, 1.0f)
		&& FMath::IsNearlyEqual(FMath::Abs(Look.Pitch), 90.0f, 1.0f))
	{
		Look.Yaw = 90.0f;
	}
	Look.Pitch = 0.0f;
	Look.Roll = 0.0f;
	return Look;
}

void EnableDynamicLighting(UWorld* World)
{
	if (!World)
	{
		return;
	}
	if (AWorldSettings* Settings = World->GetWorldSettings())
	{
		Settings->bForceNoPrecomputedLighting = true;
	}
	int32 Converted = 0;
	for (TActorIterator<AStaticMeshActor> It(World); It; ++It)
	{
		if (UStaticMeshComponent* Mesh = It->GetStaticMeshComponent())
		{
			if (Mesh->Mobility == EComponentMobility::Static)
			{
				Mesh->SetMobility(EComponentMobility::Movable);
				++Converted;
			}
		}
	}

	const FName FillTag(TEXT("BioShockSliceFill"));
	bool bHasFill = false;
	for (TActorIterator<ADirectionalLight> It(World); It; ++It)
	{
		if (It->Tags.Contains(FillTag))
		{
			bHasFill = true;
			break;
		}
	}
	if (!bHasFill)
	{
		FActorSpawnParameters Params;
		Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
		if (ADirectionalLight* Sun = World->SpawnActor<ADirectionalLight>(
				ADirectionalLight::StaticClass(),
				FVector::ZeroVector,
				FRotator(-46.0f, -35.0f, 0.0f),
				Params))
		{
			Sun->Tags.Add(FillTag);
			Sun->SetMobility(EComponentMobility::Movable);
			if (ULightComponent* Light = Sun->GetLightComponent())
			{
				Light->SetIntensity(12.0f);
			}
		}
		if (ASkyLight* Sky = World->SpawnActor<ASkyLight>(
				ASkyLight::StaticClass(), FVector::ZeroVector, FRotator::ZeroRotator, Params))
		{
			Sky->Tags.Add(FillTag);
			if (USkyLightComponent* SkyComp = Sky->GetLightComponent())
			{
				SkyComp->SetMobility(EComponentMobility::Movable);
				SkyComp->SetIntensity(1.0f);
				SkyComp->SetRealTimeCaptureEnabled(true);
				SkyComp->RecaptureSky();
			}
		}
	}

	UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_SLICE_LIGHTING movable=%d fill=%d"), Converted, bHasFill ? 0 : 1);
}
}

AShockGameMode::AShockGameMode()
{
	DefaultPawnClass = AShockPlayer::StaticClass();
}

AActor* AShockGameMode::ChoosePlayerStart_Implementation(AController* Player)
{
	if (UWorld* World = GetWorld())
	{
		for (TActorIterator<APlayerStart> It(World); It; ++It)
		{
			for (const FName& Tag : It->Tags)
			{
				if (Tag.ToString().StartsWith(TEXT("BioShockPossess=")))
				{
					UE_LOG(
						LogTemp,
						Display,
						TEXT("BIOSHOCK_CHOOSE_START tagged label=%s loc=%s"),
						*It->GetActorLabel(),
						*It->GetActorLocation().ToString());
					return *It;
				}
			}
		}
		for (TActorIterator<APlayerStart> It(World); It; ++It)
		{
			const FString Label = It->GetActorLabel();
			if (Label.Equals(TEXT("MedicalStart")) || Label.Equals(TEXT("BioShock_MedicalStart")))
			{
				UE_LOG(
					LogTemp,
					Display,
					TEXT("BIOSHOCK_CHOOSE_START label=%s loc=%s"),
					*Label,
					*It->GetActorLocation().ToString());
				return *It;
			}
		}
		UE_LOG(LogTemp, Warning, TEXT("BIOSHOCK_CHOOSE_START fallback to engine default"));
	}
	return Super::ChoosePlayerStart_Implementation(Player);
}

void AShockGameMode::SnapPawnToStart(APawn* Pawn, AActor* Start)
{
	if (!Pawn || !Start)
	{
		return;
	}

	UWorld* World = Pawn->GetWorld();
	FVector Loc = Start->GetActorLocation();
	const FRotator Rot = PlayableStartRotation(Start);

	// PlayerStart is the authored capsule center. A downward trace that begins above the
	// room hits the roof first (MedicalStart +400 uu landed at Z=8248 — the hull top).
	if (ACharacter* Character = Cast<ACharacter>(Pawn))
	{
		const UCapsuleComponent* Capsule = Character->GetCapsuleComponent();
		const float HalfHeight = Capsule ? Capsule->GetScaledCapsuleHalfHeight() : 88.0f;
		if (World)
		{
			const FVector TraceStart = Loc + FVector(0.0f, 0.0f, 8.0f);
			const FVector TraceEnd = Loc - FVector(0.0f, 0.0f, HalfHeight + 40.0f);
			FHitResult Hit;
			FCollisionQueryParams Params(SCENE_QUERY_STAT(BioShockSnapSpawn), false, Pawn);
			if (World->LineTraceSingleByChannel(Hit, TraceStart, TraceEnd, ECC_WorldStatic, Params)
				&& Hit.ImpactNormal.Z > 0.5f)
			{
				Loc.Z = Hit.Location.Z + HalfHeight + 2.0f;
			}
		}
	}

	Pawn->SetActorLocationAndRotation(Loc, Rot, false, nullptr, ETeleportType::TeleportPhysics);
}

void AShockGameMode::EquipStarterWeapon(AShockPlayer* Player)
{
	if (!Player || Player->GetEquippedWeapon())
	{
		return;
	}

	UWorld* World = GetWorld();
	if (!World)
	{
		return;
	}

	FActorSpawnParameters Params;
	Params.Owner = Player;
	Params.Instigator = Player;
	AShockWeapon* Weapon = World->SpawnActor<AShockWeapon>(
		AShockWeapon::StaticClass(),
		Player->GetActorLocation(),
		Player->GetActorRotation(),
		Params);
	if (!Weapon)
	{
		return;
	}

	Weapon->ConfigureHitscan(25.0f, 10000.0f);
	Weapon->ConfigureAmmo(50, 150, 10.0f, 2.5f);
	Weapon->InitializeAmmoFullMag(150);

	if (USkeletalMesh* TommyGun = LoadObject<USkeletalMesh>(
			nullptr,
			TEXT("/Game/BioShockWeapons/WP_TommyGun/WP_TommyGun.WP_TommyGun")))
	{
		Weapon->Mesh->SetSkeletalMesh(TommyGun);
	}

	Player->EquipWeapon(Weapon);
}

namespace
{
FName ResolveSliceRangedArchetypeKey()
{
	static const FName Candidates[] = {
		FName(TEXT("ThuggishSplicer")),
		FName(TEXT("LeadheadSplicer")),
		FName(TEXT("MachineGunMutant")),
		FName(TEXT("RangedAggressor")),
	};
	for (const FName Key : Candidates)
	{
		if (UShockAiArchetype* Archetype = UShockAiArchetypeLibrary::FindByKey(Key))
		{
			if (Archetype->bIsRanged)
			{
				return Key;
			}
		}
	}
	return NAME_None;
}

void ConfigureSlicePlayerLabel(AShockPlayer* Player)
{
	if (!Player)
	{
		return;
	}
#if WITH_EDITOR
	Player->SetActorLabel(TEXT("SlicePlayer"));
#endif
}

void ApplySliceCapsuleCollision(ABaseShockAI* AI)
{
	if (!AI)
	{
		return;
	}
	if (UCapsuleComponent* Capsule = AI->GetCapsuleComponent())
	{
		Capsule->SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
		Capsule->SetCollisionObjectType(ECC_Pawn);
		Capsule->SetCollisionResponseToAllChannels(ECR_Ignore);
		Capsule->SetCollisionResponseToChannel(ECC_Pawn, ECR_Block);
		Capsule->SetCollisionResponseToChannel(ECC_Visibility, ECR_Block);
		Capsule->SetCollisionResponseToChannel(ECC_Camera, ECR_Block);
	}
}

void ApplySliceBabyJaneMeshFallback(ABaseShockAI* AI, FName ArchetypeKey)
{
	if (!AI || ArchetypeKey != FName(TEXT("Agg_BabyJane")))
	{
		return;
	}
	if (USkeletalMeshComponent* Body = AI->GetMesh())
	{
		if (!Body->GetSkeletalMeshAsset())
		{
			if (USkeletalMesh* MeshAsset = LoadObject<USkeletalMesh>(
					nullptr,
					TEXT("/Game/BioShockCharacters/AggressorBabyJane/AggressorBabyJane.AggressorBabyJane")))
			{
				Body->SetSkeletalMesh(MeshAsset);
				Body->SetHiddenInGame(false);
				Body->SetCollisionEnabled(ECollisionEnabled::NoCollision);
			}
		}
	}
}

void EquipSliceRangedWeaponIfNeeded(UWorld* World, ABaseShockAI* AI, bool bForceRangedWeapon)
{
	if (!World || !AI || AI->HasAIWeapon() || !bForceRangedWeapon)
	{
		return;
	}

	FActorSpawnParameters Params;
	Params.Owner = AI;
	Params.Instigator = AI;
	AShockWeapon* Weapon = World->SpawnActor<AShockWeapon>(
		AShockWeapon::StaticClass(),
		AI->GetActorLocation(),
		AI->GetActorRotation(),
		Params);
	if (!Weapon)
	{
		return;
	}

	Weapon->ConfigureHitscan(20.0f, 10000.0f);
	AI->EquipAIWeapon(Weapon);
}
}

ABaseShockAI* AShockGameMode::SpawnOneSliceEnemy(
	AShockPlayer* Player,
	int32 Index,
	FName ArchetypeKey,
	const FVector& SpawnLoc,
	const FRotator& SpawnRot,
	bool bForceRangedWeapon)
{
	UWorld* World = GetWorld();
	if (!World || !Player)
	{
		return nullptr;
	}

	FActorSpawnParameters Params;
	Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
	ABaseShockAI* AI = World->SpawnActor<ABaseShockAI>(
		ABaseShockAI::StaticClass(),
		SpawnLoc,
		SpawnRot,
		Params);
	if (!AI)
	{
		return nullptr;
	}

	const FString Label = FString::Printf(TEXT("SliceEnemy%d"), Index);
	AI->ConfigureIdentity(ArchetypeKey, FName(*Label));
	AI->ApplyArchetypeLookup(ArchetypeKey);
	EquipSliceRangedWeaponIfNeeded(World, AI, bForceRangedWeapon);
	AI->EnsureHealthInitialized();
	ApplySliceCapsuleCollision(AI);
	ApplySliceBabyJaneMeshFallback(AI, ArchetypeKey);
	AI->AddTargetToAttackOnSight(FName(TEXT("SlicePlayer")));
#if WITH_EDITOR
	AI->SetActorLabel(Label);
#endif

	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_SLICE_SPAWN label=%s loc=%s player=%s"),
		*Label,
		*AI->GetActorLocation().ToString(),
		*Player->GetActorLocation().ToString());

	return AI;
}

void AShockGameMode::SpawnSliceEnemyStaggered(
	AShockPlayer* Player,
	AActor* StartSpot,
	int32 Index,
	FVector SpawnLoc,
	FRotator SpawnRot,
	FName ArchetypeKey,
	bool bForceRangedWeapon)
{
	(void)StartSpot;
	SpawnOneSliceEnemy(Player, Index, ArchetypeKey, SpawnLoc, SpawnRot, bForceRangedWeapon);
}

void AShockGameMode::SpawnSliceEncounter(AShockPlayer* Player, AActor* StartSpot)
{
	UWorld* World = GetWorld();
	if (!World || !Player)
	{
		return;
	}

	for (TActorIterator<ABaseShockAI> It(World); It; ++It)
	{
		if (*It && (*It)->GetScriptLabel() == FName(TEXT("SliceEnemy0")))
		{
			return;
		}
	}

	ConfigureSlicePlayerLabel(Player);

	FVector Forward = PlayableStartRotation(StartSpot).Vector();
	Forward.Z = 0.0f;
	if (Forward.IsNearlyZero())
	{
		Forward = FVector::YAxisVector;
	}
	Forward.Normalize();
	const FVector Right = FVector::CrossProduct(FVector::UpVector, Forward).GetSafeNormal();
	const FVector PlayerLoc = Player->GetActorLocation();
	const float PlayerZ = PlayerLoc.Z;
	const FRotator FacePlayer = (-Forward).Rotation();

	const FVector MeleeLeft = PlayerLoc + Forward * 375.0f + Right * (-100.0f);
	const FVector MeleeRight = PlayerLoc + Forward * 375.0f + Right * 100.0f;
	const FVector RangedBack = PlayerLoc + Forward * 800.0f;

	FVector MeleeLeftLoc = MeleeLeft;
	FVector MeleeRightLoc = MeleeRight;
	FVector RangedLoc = RangedBack;
	MeleeLeftLoc.Z = PlayerZ;
	MeleeRightLoc.Z = PlayerZ;
	RangedLoc.Z = PlayerZ;

	SpawnOneSliceEnemy(
		Player,
		0,
		FName(TEXT("Agg_BabyJane")),
		MeleeLeftLoc,
		FacePlayer,
		false);

	const FName RangedArchetype = ResolveSliceRangedArchetypeKey();
	const bool bForceRangedWeapon = RangedArchetype.IsNone();
	const FName RangedKey = bForceRangedWeapon ? FName(TEXT("Agg_BabyJane")) : RangedArchetype;

	World->GetTimerManager().SetTimer(
		SliceEncounterSpawnTimer1,
		FTimerDelegate::CreateUObject(
			this,
			&AShockGameMode::SpawnSliceEnemyStaggered,
			Player,
			StartSpot,
			1,
			MeleeRightLoc,
			FacePlayer,
			FName(TEXT("Agg_BabyJane")),
			false),
		1.5f,
		false);

	World->GetTimerManager().SetTimer(
		SliceEncounterSpawnTimer2,
		FTimerDelegate::CreateUObject(
			this,
			&AShockGameMode::SpawnSliceEnemyStaggered,
			Player,
			StartSpot,
			2,
			RangedLoc,
			FacePlayer,
			RangedKey,
			bForceRangedWeapon),
		3.0f,
		false);
}

void AShockGameMode::VerifySliceEncounter(AShockPlayer* Player)
{
	UWorld* World = GetWorld();
	if (!World)
	{
		UE_LOG(LogTemp, Error, TEXT("BIOSHOCK_ENCOUNTER_FAIL reason=no_world"));
		return;
	}

	int32 Spawned = 0;
	int32 Armed = 0;
	int32 Targeting = 0;
	for (TActorIterator<ABaseShockAI> It(World); It; ++It)
	{
		if (!*It)
		{
			continue;
		}
		const FString Label = It->GetScriptLabel().ToString();
		if (!Label.StartsWith(TEXT("SliceEnemy")))
		{
			continue;
		}

		++Spawned;
		const bool bWeapon = It->HasAIWeapon();
		const bool bTarget = It->HasAttackOnSightLabel(FName(TEXT("SlicePlayer")));
		if (bWeapon)
		{
			++Armed;
		}
		if (bTarget)
		{
			++Targeting;
		}
		UE_LOG(
			LogTemp,
			Display,
			TEXT("BIOSHOCK_ENCOUNTER_ENEMY label=%s weapon=%d target=%d"),
			*Label,
			bWeapon ? 1 : 0,
			bTarget ? 1 : 0);
	}

	(void)Player;
	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_ENCOUNTER spawned=%d armed=%d targeting=%d"),
		Spawned,
		Armed,
		Targeting);
}

void AShockGameMode::SpawnSliceAmmoPickup(AShockPlayer* Player, AActor* StartSpot, ABaseShockAI* Enemy)
{
	UWorld* World = GetWorld();
	if (!World || !Player)
	{
		return;
	}

	int32 Existing = 0;
	for (TActorIterator<AShockAmmoPickup> It(World); It; ++It)
	{
		if (*It && It->Tags.Contains(FName(TEXT("SliceAmmoPickup"))))
		{
			++Existing;
		}
	}
	if (Existing >= 2)
	{
		return;
	}

	FVector BaseLoc = Player->GetActorLocation();
	if (Enemy)
	{
		BaseLoc = Enemy->GetActorLocation() + FVector(0.0f, 120.0f, 0.0f);
	}
	else if (StartSpot)
	{
		BaseLoc = StartSpot->GetActorLocation() + FVector(180.0f, 0.0f, 0.0f);
	}
	else
	{
		BaseLoc += FVector(180.0f, 0.0f, 0.0f);
	}

	const FVector Offsets[2] = {FVector::ZeroVector, FVector(0.0f, 160.0f, 0.0f)};
	for (int32 PickupIndex = Existing; PickupIndex < 2; ++PickupIndex)
	{
		const FVector SpawnLoc = BaseLoc + Offsets[PickupIndex];

		FActorSpawnParameters Params;
		Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
		AShockAmmoPickup* Pickup = World->SpawnActor<AShockAmmoPickup>(
			AShockAmmoPickup::StaticClass(),
			SpawnLoc,
			FRotator::ZeroRotator,
			Params);
		if (!Pickup)
		{
			continue;
		}

		Pickup->Tags.Add(FName(TEXT("SliceAmmoPickup")));
		Pickup->PickupAmount = 60;
#if WITH_EDITOR
		Pickup->SetActorLabel(FString::Printf(TEXT("SliceAmmoPickup%d"), PickupIndex));
#endif
		UE_LOG(
			LogTemp,
			Display,
			TEXT("BIOSHOCK_SLICE_AMMO_PICKUP index=%d loc=%s amount=%d"),
			PickupIndex,
			*Pickup->GetActorLocation().ToString(),
			Pickup->PickupAmount);
	}
}

UShockDeathRespawnHandler* AShockGameMode::EnsureDeathHandler()
{
	if (!DeathHandler)
	{
		DeathHandler = NewObject<UShockDeathRespawnHandler>(this);
	}
	DeathHandler->RespawnDelaySeconds = RespawnDelaySeconds;
	DeathHandler->bReloadLevelOnDeath = bReloadLevelOnDeath;
	return DeathHandler;
}

void AShockGameMode::BindPlayerDeathHandling(AShockPlayer* Player, AActor* RespawnStart)
{
	if (UShockDeathRespawnHandler* Handler = EnsureDeathHandler())
	{
		Handler->Initialize(GetWorld(), Player, RespawnStart);
	}
}

bool AShockGameMode::IsRespawnPending() const
{
	return DeathHandler && DeathHandler->IsRespawnPending();
}

void AShockGameMode::AdvanceRespawnForVerify(float DeltaSeconds)
{
	if (DeathHandler)
	{
		DeathHandler->AdvanceRespawnForVerify(DeltaSeconds);
	}
}

void AShockGameMode::EnsureHudForPlayer(APlayerController* PC)
{
	if (!PC)
	{
		return;
	}
	if (!PlayerHud)
	{
		PlayerHud = CreateWidget<UShockHudWidget>(PC, UShockHudWidget::StaticClass());
	}
	if (PlayerHud && !PlayerHud->IsInViewport())
	{
		PlayerHud->AddToViewport(0);
	}
}

void AShockGameMode::VerifySliceFire(AShockPlayer* Player, ABaseShockAI* Enemy)
{
	if (!Player || !Enemy)
	{
		UE_LOG(LogTemp, Error, TEXT("BIOSHOCK_SLICE_FAIL reason=missing_actor"));
		return;
	}

	const bool bMesh = Enemy->GetMesh() && Enemy->GetMesh()->GetSkeletalMeshAsset() != nullptr;
	const float HealthBefore = Enemy->GetCurrentHealth();

	if (APlayerController* PC = Cast<APlayerController>(Player->GetController()))
	{
		const FVector ToEnemy = Enemy->GetActorLocation() - Player->GetActorLocation();
		PC->SetControlRotation(ToEnemy.Rotation());
	}

	const bool bFired = Player->TryFireEquippedWeapon();
	const float HealthAfter = Enemy->GetCurrentHealth();
	const FString EnemyLabel = Enemy->GetScriptLabel().ToString();
	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_SLICE_OK enemy=%s mesh=%d health_before=%.1f health_after=%.1f fire=%d"),
		*EnemyLabel,
		bMesh ? 1 : 0,
		HealthBefore,
		HealthAfter,
		bFired ? 1 : 0);
}

void AShockGameMode::PostLogin(APlayerController* NewPlayer)
{
	Super::PostLogin(NewPlayer);

	EnableDynamicLighting(GetWorld());

	if (FParse::Param(FCommandLine::Get(), TEXT("bioshockverifyphysics")))
	{
		UWorld* World = GetWorld();
		FTimerHandle TimerHandle;
		World->GetTimerManager().SetTimer(
			TimerHandle,
			FTimerDelegate::CreateLambda([World]()
			{
				FString Error;
				if (UShockPhysicsLibrary::RunHeadlessSelfTest(World, Error))
				{
					UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_PHYSICS_OK"));
				}
				else
				{
					UE_LOG(LogTemp, Error, TEXT("BIOSHOCK_PHYSICS_FAIL reason=%s"), *Error);
				}
				FGenericPlatformMisc::RequestExit(false);
			}),
			0.1f,
			false);
		return;
	}

	APawn* Pawn = NewPlayer ? NewPlayer->GetPawn() : nullptr;
	if (Pawn && NewPlayer)
	{
		if (AActor* Start = ChoosePlayerStart_Implementation(NewPlayer))
		{
			SnapPawnToStart(Pawn, Start);
			NewPlayer->SetControlRotation(PlayableStartRotation(Start));
			if (AShockPlayer* Player = Cast<AShockPlayer>(Pawn))
			{
				EquipStarterWeapon(Player);
				NewPlayer->SetViewTarget(Player);
				BindPlayerDeathHandling(Player, Start);
				EnsureHudForPlayer(NewPlayer);
				SpawnSliceEncounter(Player, Start);
				ABaseShockAI* PrimaryEnemy = nullptr;
				if (UWorld* World = GetWorld())
				{
					for (TActorIterator<ABaseShockAI> It(World); It; ++It)
					{
						if (*It && (*It)->GetScriptLabel() == FName(TEXT("SliceEnemy0")))
						{
							PrimaryEnemy = *It;
							break;
						}
					}
				}
				SpawnSliceAmmoPickup(Player, Start, PrimaryEnemy);
				if (FParse::Param(FCommandLine::Get(), TEXT("bioshockverifypossess")))
				{
					VerifySliceFire(Player, PrimaryEnemy);
				}
				if (FParse::Param(FCommandLine::Get(), TEXT("bioshockverifyencounter")))
				{
					if (UWorld* World = GetWorld())
					{
						TWeakObjectPtr<AShockPlayer> WeakPlayer = Player;
						World->GetTimerManager().SetTimer(
							SliceEncounterVerifyTimer,
							FTimerDelegate::CreateLambda([this, WeakPlayer]()
							{
								if (WeakPlayer.IsValid())
								{
									VerifySliceEncounter(WeakPlayer.Get());
								}
								FGenericPlatformMisc::RequestExit(false);
							}),
							3.5f,
							false);
					}
					return;
				}
			}
		}
		else if (AShockPlayer* Player = Cast<AShockPlayer>(Pawn))
		{
			EquipStarterWeapon(Player);
			NewPlayer->SetViewTarget(Player);
			EnsureHudForPlayer(NewPlayer);
		}
	}

	if (FParse::Param(FCommandLine::Get(), TEXT("bioshockverifyhud")))
	{
		if (UShockHudWidget::RunHeadlessHudVerify(GetWorld()))
		{
			UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_HUD_VERIFY_OK"));
		}
		else
		{
			UE_LOG(
				LogTemp,
				Error,
				TEXT("BIOSHOCK_HUD_VERIFY_FAIL reason=%s"),
				*UShockHudWidget::GetLastHudVerifyError());
		}
		FGenericPlatformMisc::RequestExit(false);
		return;
	}

	const bool bVerifyPossess = FParse::Param(FCommandLine::Get(), TEXT("bioshockverifypossess"));
	if (!bVerifyPossess)
	{
		return;
	}

	if (!Pawn)
	{
		UE_LOG(LogTemp, Error, TEXT("BIOSHOCK_POSSESS_FAIL reason=no_pawn"));
	}
	else
	{
		const FVector Loc = Pawn->GetActorLocation();
		const AShockPlayer* Player = Cast<AShockPlayer>(Pawn);
		const bool bPlayable = Player && Player->IsPlayableInputEnabled();
		const bool bWeapon = Player && Player->GetEquippedWeapon() != nullptr;
		UE_LOG(
			LogTemp,
			Display,
			TEXT("BIOSHOCK_POSSESS_OK class=%s x=%.2f y=%.2f z=%.2f playable=%d weapon=%d"),
			*Pawn->GetClass()->GetName(),
			Loc.X,
			Loc.Y,
			Loc.Z,
			bPlayable ? 1 : 0,
			bWeapon ? 1 : 0);
	}

	FGenericPlatformMisc::RequestExit(false);
}
