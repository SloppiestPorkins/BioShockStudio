#include "ShockGameMode.h"
#include "BaseShockAI.h"
#include "ShockAiArchetype.h"
#include "ShockAmmoPickup.h"
#include "ShockCarryState.h"
#include "ShockConsumablePickup.h"
#include "ShockDeathRespawnHandler.h"
#include "ShockGameInstance.h"
#include "ShockHudWidget.h"
#include "ShockPhysicsLibrary.h"
#include "ShockPlayer.h"
#include "ShockElectroBoltPlasmid.h"
#include "ShockEnragePlasmid.h"
#include "ShockIncineratePlasmid.h"
#include "ShockInsectSwarmPlasmid.h"
#include "ShockTelekinesisPlasmid.h"
#include "ShockWinterBlastPlasmid.h"
#include "ShockTurret.h"
#include "ShockSecurityCamera.h"
#include "ShockSecurityDeviceTypes.h"
#include "ShockResearchCamera.h"
#include "ShockWeapon.h"
#include "ShockWeaponDef.h"

#include "Camera/CameraComponent.h"
#include "CollisionQueryParams.h"
#include "Components/CapsuleComponent.h"
#include "Components/SkeletalMeshComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/DirectionalLight.h"
#include "Engine/SkeletalMesh.h"
#include "Engine/SkyLight.h"
#include "Engine/StaticMeshActor.h"
#include "Engine/Engine.h"
#include "Engine/World.h"
#include "TimerManager.h"
#include "GameFramework/WorldSettings.h"
#include "Components/LightComponent.h"
#include "Components/SkyLightComponent.h"
#include "EngineUtils.h"
#include "GameFramework/Character.h"
#include "GameFramework/PlayerController.h"
#include "GameFramework/PlayerStart.h"
#include "HAL/FileManager.h"
#include "HAL/PlatformMisc.h"
#include "Kismet/GameplayStatics.h"
#include "Misc/CommandLine.h"
#include "Misc/Paths.h"
#include "Engine/SceneCapture2D.h"
#include "Components/SceneCaptureComponent2D.h"
#include "Engine/TextureRenderTarget2D.h"
#include "Kismet/KismetRenderingLibrary.h"
#include "Camera/PlayerCameraManager.h"
#include "NavMesh/NavMeshBoundsVolume.h"
#include "NavMesh/RecastNavMesh.h"
#include "NavigationSystem.h"

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

void EnsureSliceNavMeshBounds(UWorld* World, const FVector& Center)
{
	if (!World)
	{
		return;
	}

	const FName NavTag(TEXT("BioShockSliceNav"));
	for (TActorIterator<ANavMeshBoundsVolume> It(World); It; ++It)
	{
		if (*It && It->Tags.Contains(NavTag))
		{
			return;
		}
	}

	FActorSpawnParameters Params;
	Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
	if (ANavMeshBoundsVolume* Volume = World->SpawnActor<ANavMeshBoundsVolume>(
			ANavMeshBoundsVolume::StaticClass(),
			Center,
			FRotator::ZeroRotator,
			Params))
	{
		Volume->Tags.Add(NavTag);
		// Default brush is 200 uu per side; scale to ~6000 x 6000 x 3000 uu.
		Volume->SetActorScale3D(FVector(30.0f, 30.0f, 15.0f));
#if WITH_EDITOR
		Volume->SetActorLabel(TEXT("BioShockSliceNavBounds"));
#endif
	}
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
		if (const UShockGameInstance* GI = UShockGameInstance::GetShockInstance(World))
		{
			if (GI->HasPendingArrival())
			{
				const FName ArrivalLabel = GI->GetPendingArrivalStartLabel();
				if (!ArrivalLabel.IsNone())
				{
					for (TActorIterator<APlayerStart> It(World); It; ++It)
					{
						const FString Label = It->GetActorLabel();
						if (Label.Equals(ArrivalLabel.ToString(), ESearchCase::IgnoreCase))
						{
							UE_LOG(
								LogTemp,
								Display,
								TEXT("BIOSHOCK_CHOOSE_START arrival label=%s loc=%s"),
								*Label,
								*It->GetActorLocation().ToString());
							return *It;
						}
					}
					UE_LOG(
						LogTemp,
						Warning,
						TEXT("BIOSHOCK_CHOOSE_START arrival label=%s not found; using default"),
						*ArrivalLabel.ToString());
				}
			}
		}

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

	UWorld* World = Player->GetWorld();
	if (!World)
	{
		return;
	}

	Player->GiveWeaponByDef(TEXT("Wrench"), 0);
	Player->GiveWeaponByDef(TEXT("Pistol"), 1);

	AShockWeapon* TommyGun = Player->GiveWeaponByDef(TEXT("TommyGun"), 2);
	if (TommyGun)
	{
		TommyGun->InitializeAmmoFullMag(150);
		if (USkeletalMesh* TommyGunMesh = LoadObject<USkeletalMesh>(
				nullptr,
				TEXT("/Game/BioShockWeapons/WP_TommyGun/WP_TommyGun.WP_TommyGun")))
		{
			TommyGun->Mesh->SetSkeletalMesh(TommyGunMesh);
		}
	}

	Player->GiveWeaponByDef(TEXT("Shotgun"), 3);
	Player->GiveWeaponByDef(TEXT("ChemicalThrower"), 5);
	Player->GiveWeaponByDef(TEXT("Crossbow"), 6);
	Player->GiveWeapon(AShockResearchCamera::StaticClass(), 7);
	Player->SelectWeaponSlot(2);

	// C3 slice: Electro Bolt slot 0, Incinerate 1, Telekinesis 2, Winter Blast 3, Insect Swarm 4, Enrage 5.
	Player->MaxEve = 100.0f;
	Player->RefillEve(100.0f);
	Player->EquipPlasmid(UShockElectroBoltPlasmid::StaticClass(), 0);
	Player->EquipPlasmid(UShockIncineratePlasmid::StaticClass(), 1);
	Player->EquipPlasmid(UShockTelekinesisPlasmid::StaticClass(), 2);
	Player->EquipPlasmid(UShockWinterBlastPlasmid::StaticClass(), 3);
	Player->EquipPlasmid(UShockInsectSwarmPlasmid::StaticClass(), 4);
	Player->EquipPlasmid(UShockEnragePlasmid::StaticClass(), 5);
	Player->ActivePlasmidSlot = 0;

	Player->AddStackToInventory(FName(TEXT("FirstAidKit")), 1);
	Player->AddStackToInventory(FName(TEXT("EveHypo")), 1);
}

void AShockGameMode::TravelToLevel(const FString& Map, FName StartLabel)
{
	UWorld* World = GetWorld();
	if (!World || Map.IsEmpty())
	{
		return;
	}

	if (UShockGameInstance* GI = UShockGameInstance::GetShockInstance(World))
	{
		if (AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World))
		{
			UShockCarryState* Carry = UShockCarryState::Capture(Player);
			GI->SetPendingCarry(Carry, StartLabel);
		}
	}

	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_TRAVEL to=%s start=%s"),
		*Map,
		*StartLabel.ToString());

	UGameplayStatics::OpenLevel(this, FName(*Map));
}

bool AShockGameMode::ApplyArrivalLoadout(AShockPlayer* Player)
{
	if (!Player)
	{
		return false;
	}

	if (UShockGameInstance* GI = UShockGameInstance::GetShockInstance(Player->GetWorld()))
	{
		if (GI->HasPendingArrival())
		{
			return GI->ConsumePendingArrival(Player);
		}
	}

	EquipStarterWeapon(Player);
	return false;
}

void AShockGameMode::EquipStarterWeaponForVerify(AShockPlayer* Player)
{
	EquipStarterWeapon(Player);
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

void AShockGameMode::EnsureSliceNavigation(AShockPlayer* Player, AActor* StartSpot)
{
	UWorld* World = GetWorld();
	if (!World)
	{
		return;
	}

	FVector PlayerLoc = Player ? Player->GetActorLocation() : FVector::ZeroVector;
	if (StartSpot)
	{
		PlayerLoc = StartSpot->GetActorLocation();
	}

	FVector Forward = PlayableStartRotation(StartSpot).Vector();
	Forward.Z = 0.0f;
	if (Forward.IsNearlyZero())
	{
		Forward = FVector::YAxisVector;
	}
	Forward.Normalize();
	const FVector Right = FVector::CrossProduct(FVector::UpVector, Forward).GetSafeNormal();
	const float PlayerZ = PlayerLoc.Z;

	const FVector MeleeLeft = PlayerLoc + Forward * 375.0f + Right * (-100.0f);
	const FVector MeleeRight = PlayerLoc + Forward * 375.0f + Right * 100.0f;
	const FVector RangedBack = PlayerLoc + Forward * 800.0f;
	FVector Center = (PlayerLoc + MeleeLeft + MeleeRight + RangedBack) * 0.25f;
	Center.Z = PlayerZ + 150.0f;

	EnsureSliceNavMeshBounds(World, Center);

	int32 BoundsCount = 0;
	for (TActorIterator<ANavMeshBoundsVolume> It(World); It; ++It)
	{
		if (*It)
		{
			++BoundsCount;
		}
	}

	int32 NavMeshCount = 0;
	for (TActorIterator<ARecastNavMesh> It(World); It; ++It)
	{
		if (*It)
		{
			++NavMeshCount;
		}
	}

	if (UNavigationSystemV1* NavSys = UNavigationSystemV1::GetCurrent(World))
	{
		NavSys->Build();
		if (NavMeshCount == 0)
		{
			if (const ANavigationData* NavData = NavSys->GetDefaultNavDataInstance(FNavigationSystem::DontCreate))
			{
				if (NavData->IsA<ARecastNavMesh>())
				{
					NavMeshCount = 1;
				}
			}
		}
	}

	UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_NAV bounds=%d navmesh=%d"), BoundsCount, NavMeshCount);
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
	EnsureSliceNavigation(Player, StartSpot);

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

	SpawnSliceTurret(Player, StartSpot);
	SpawnSliceSecurityCamera(Player, StartSpot);
}

void AShockGameMode::SpawnSliceTurret(AShockPlayer* Player, AActor* StartSpot)
{
	if (!bEnableSliceTurret || !Player || !StartSpot)
	{
		return;
	}

	UWorld* World = GetWorld();
	if (!World)
	{
		return;
	}

	for (TActorIterator<AShockTurret> It(World); It; ++It)
	{
		if (*It && It->DeviceLabel == FName(TEXT("SliceTurret")))
		{
			return;
		}
	}

	FVector Forward = PlayableStartRotation(StartSpot).Vector();
	Forward.Z = 0.0f;
	if (Forward.IsNearlyZero())
	{
		Forward = FVector::YAxisVector;
	}
	Forward.Normalize();
	const FVector Right = FVector::CrossProduct(FVector::UpVector, Forward).GetSafeNormal();
	const FVector SpawnLoc = Player->GetActorLocation() + Forward * 500.0f + Right * 200.0f;

	FActorSpawnParameters Params;
	Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
	AShockTurret* Turret = World->SpawnActor<AShockTurret>(
		AShockTurret::StaticClass(),
		SpawnLoc,
		(-Forward).Rotation(),
		Params);
	if (!Turret)
	{
		return;
	}

	Turret->SetDeviceLabel(FName(TEXT("SliceTurret")));
	Turret->SetAllegiance(EShockDeviceAllegiance::Hostile);
#if WITH_EDITOR
	Turret->SetActorLabel(TEXT("SliceTurret"));
#endif
}

void AShockGameMode::SpawnSliceSecurityCamera(AShockPlayer* Player, AActor* StartSpot)
{
	if (!bEnableSliceSecurity || !Player || !StartSpot)
	{
		return;
	}

	UWorld* World = GetWorld();
	if (!World)
	{
		return;
	}

	for (TActorIterator<AShockSecurityCamera> It(World); It; ++It)
	{
		if (*It && It->DeviceLabel == FName(TEXT("SliceSecurityCamera")))
		{
			return;
		}
	}

	FVector Forward = PlayableStartRotation(StartSpot).Vector();
	Forward.Z = 0.0f;
	if (Forward.IsNearlyZero())
	{
		Forward = FVector::YAxisVector;
	}
	Forward.Normalize();
	const FVector Right = FVector::CrossProduct(FVector::UpVector, Forward).GetSafeNormal();
	const FVector PlayerLoc = Player->GetActorLocation();
	const FVector CamLoc = PlayerLoc + Forward * 500.0f + Right * 200.0f + FVector(0.0f, 0.0f, 120.0f);
	const FRotator FacePlayer = (PlayerLoc - CamLoc).Rotation();

	FActorSpawnParameters Params;
	Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
	AShockSecurityCamera* Camera = World->SpawnActor<AShockSecurityCamera>(
		AShockSecurityCamera::StaticClass(),
		CamLoc,
		FacePlayer,
		Params);
	if (!Camera)
	{
		return;
	}

	Camera->SetDeviceLabel(FName(TEXT("SliceSecurityCamera")));
	Camera->SetAllegiance(EShockDeviceAllegiance::Hostile);
#if WITH_EDITOR
	Camera->SetActorLabel(TEXT("SliceSecurityCamera"));
#endif
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

void AShockGameMode::SpawnSliceConsumablePickup(
	AShockPlayer* Player,
	AActor* StartSpot,
	ABaseShockAI* Enemy)
{
	if (!bEnableSlicePickup || !Player)
	{
		return;
	}

	UWorld* World = GetWorld();
	if (!World)
	{
		return;
	}

	for (TActorIterator<AShockConsumablePickup> It(World); It; ++It)
	{
		if (*It && It->Tags.Contains(FName(TEXT("SliceConsumablePickup"))))
		{
			return;
		}
	}

	FVector SpawnLoc = Player->GetActorLocation();
	if (Enemy)
	{
		SpawnLoc = Enemy->GetActorLocation() + FVector(0.0f, -120.0f, 0.0f);
	}
	else if (StartSpot)
	{
		SpawnLoc = StartSpot->GetActorLocation() + FVector(240.0f, 0.0f, 0.0f);
	}
	else
	{
		SpawnLoc += FVector(240.0f, 0.0f, 0.0f);
	}

	FActorSpawnParameters Params;
	Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
	AShockConsumablePickup* Pickup = World->SpawnActor<AShockConsumablePickup>(
		AShockConsumablePickup::StaticClass(),
		SpawnLoc,
		FRotator::ZeroRotator,
		Params);
	if (!Pickup)
	{
		return;
	}

	Pickup->PickupKind = EShockPickupKind::FirstAidKit;
	Pickup->Amount = 1;
	Pickup->Tags.Add(FName(TEXT("SliceConsumablePickup")));
#if WITH_EDITOR
	Pickup->SetActorLabel(TEXT("SliceConsumablePickup"));
#endif
	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_SLICE_CONSUMABLE_PICKUP kind=FirstAidKit loc=%s"),
		*Pickup->GetActorLocation().ToString());
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

bool AShockGameMode::BuildNavigationForVerify(UObject* WorldContextObject)
{
	UWorld* World = GEngine ? GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::ReturnNull) : nullptr;
	if (!World)
	{
		return false;
	}
	if (UNavigationSystemV1* NavSys = UNavigationSystemV1::GetCurrent(World))
	{
		NavSys->Build();
		return true;
	}
	return false;
}

bool AShockGameMode::CanProjectPointToNavigation(UObject* WorldContextObject, FVector Point)
{
	UWorld* World = GEngine ? GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::ReturnNull) : nullptr;
	if (!World)
	{
		return false;
	}
	UNavigationSystemV1* NavSys = UNavigationSystemV1::GetCurrent(World);
	if (!NavSys)
	{
		return false;
	}
	FNavLocation Projected;
	return NavSys->ProjectPointToNavigation(Point, Projected);
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
				ApplyArrivalLoadout(Player);
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
				SpawnSliceConsumablePickup(Player, Start, PrimaryEnemy);
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
			ApplyArrivalLoadout(Player);
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

	// -bioshockscreenshot: photograph the possessed scene and quit. Deliberately checked BEFORE the
	// possess verify's exit, and deliberately does NOT exit here — a shot taken on the possess frame
	// catches an unresolved scene (shaders still compiling, textures still streaming) and would be
	// worse than no shot at all, because it would look like evidence.
	if (FParse::Param(FCommandLine::Get(), TEXT("bioshockscreenshot")))
	{
		float Interval = 0.5f;
		FParse::Value(FCommandLine::Get(), TEXT("bioshockshotinterval="), Interval);
		GetWorldTimerManager().SetTimer(
			ScreenshotTimer, this, &AShockGameMode::TickScreenshotCapture,
			FMath::Max(0.05f, Interval), true);
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

void AShockGameMode::TickScreenshotCapture()
{
	++ScreenshotTicks;

	// Settle first. Shader compilation and texture streaming both land well after PostLogin, and a
	// shot taken before they do shows default materials and blurry mips — the exact false negative
	// this harness exists to prevent.
	int32 SettleTicks = 12;
	FParse::Value(FCommandLine::Get(), TEXT("bioshockshotsettle="), SettleTicks);
	if (ScreenshotTicks < FMath::Max(1, SettleTicks))
	{
		return;
	}

	if (!bScreenshotRequested)
	{
		FString Path;
		if (!FParse::Value(FCommandLine::Get(), TEXT("bioshockshotpath="), Path) || Path.IsEmpty())
		{
			Path = FPaths::ProjectDir() / TEXT("Exports/slice/bioshock_shot.png");
		}
		Path = FPaths::ConvertRelativePathToFull(Path);
		IFileManager::Get().MakeDirectory(*FPaths::GetPath(Path), true);

		bScreenshotRequested = true;

		// A SceneCapture2D rendered to a render target we own, NOT
		// FScreenshotRequest::RequestScreenshot. The backbuffer route returned a uniformly black PNG
		// from an unattended -game session - byte-identical 30KB output for two different maps, one
		// of which had a rescaled lighting rig - so it was capturing an unpresented surface rather
		// than the scene. Rendering to our own target does not depend on the swap chain at all.
		UWorld* CaptureWorld = GetWorld();
		APlayerController* PC = CaptureWorld ? CaptureWorld->GetFirstPlayerController() : nullptr;
		if (!CaptureWorld || !PC)
		{
			UE_LOG(LogTemp, Error, TEXT("BIOSHOCK_SCREENSHOT_FAIL reason=no_player_controller"));
			GetWorldTimerManager().ClearTimer(ScreenshotTimer);
			FGenericPlatformMisc::RequestExit(false);
			return;
		}

		int32 ShotW = 1280;
		int32 ShotH = 720;
		FParse::Value(FCommandLine::Get(), TEXT("bioshockshotwidth="), ShotW);
		FParse::Value(FCommandLine::Get(), TEXT("bioshockshotheight="), ShotH);

		FVector CamLoc = FVector::ZeroVector;
		FRotator CamRot = FRotator::ZeroRotator;
		PC->GetPlayerViewPoint(CamLoc, CamRot);

		UTextureRenderTarget2D* Target =
			UKismetRenderingLibrary::CreateRenderTarget2D(CaptureWorld, ShotW, ShotH, RTF_RGBA8);
		FActorSpawnParameters CaptureParams;
		CaptureParams.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
		ASceneCapture2D* Capture =
			CaptureWorld->SpawnActor<ASceneCapture2D>(CamLoc, CamRot, CaptureParams);
		if (!Target || !Capture)
		{
			UE_LOG(LogTemp, Error, TEXT("BIOSHOCK_SCREENSHOT_FAIL reason=capture_setup"));
			GetWorldTimerManager().ClearTimer(ScreenshotTimer);
			FGenericPlatformMisc::RequestExit(false);
			return;
		}

		if (USceneCaptureComponent2D* Comp = Capture->GetCaptureComponent2D())
		{
			Comp->TextureTarget = Target;
			// FinalColorLDR: the fully post-processed image a player would see, tone mapping and
			// exposure included. SceneColor would hide the very lighting faults this exists to catch.
			Comp->CaptureSource = ESceneCaptureSource::SCS_FinalColorLDR;
			Comp->bCaptureEveryFrame = false;
			Comp->bCaptureOnMovement = false;
			if (PC->PlayerCameraManager)
			{
				Comp->FOVAngle = PC->PlayerCameraManager->GetFOVAngle();
			}
			Comp->CaptureScene();
		}

		UKismetRenderingLibrary::ExportRenderTarget(
			CaptureWorld, Target, FPaths::GetPath(Path), FPaths::GetCleanFilename(Path));
		UE_LOG(
			LogTemp, Display, TEXT("BIOSHOCK_SCREENSHOT_REQUEST path=%s %dx%d"), *Path, ShotW, ShotH);
		return;   // one more tick so the export lands before the world tears down
	}

	UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_SCREENSHOT_OK"));
	GetWorldTimerManager().ClearTimer(ScreenshotTimer);
	FGenericPlatformMisc::RequestExit(false);
}
