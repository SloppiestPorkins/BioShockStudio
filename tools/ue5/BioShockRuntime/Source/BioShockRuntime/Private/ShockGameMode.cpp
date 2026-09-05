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
#include "ShockPauseMenu.h"
#include "ShockPlayer.h"
#include "ShockRadialMenu.h"
#include "ShockStatusMenu.h"
#include "ShockWeaponSelectScreen.h"
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
#include "GameFramework/CharacterMovementComponent.h"
#include "GameFramework/PlayerController.h"
#include "GameFramework/PlayerStart.h"
#include "HAL/FileManager.h"
#include "HAL/PlatformMisc.h"
#include "Kismet/GameplayStatics.h"
#include "Misc/CommandLine.h"
#include "Misc/Paths.h"
#include "Engine/SceneCapture2D.h"
#include "Components/SceneCaptureComponent2D.h"
#include "Engine/Canvas.h"
#include "Engine/TextureRenderTarget2D.h"
#include "Kismet/KismetRenderingLibrary.h"
#include "Slate/WidgetRenderer.h"
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
	int32 RestoredCompiledWorld = 0;
	for (TActorIterator<AStaticMeshActor> It(World); It; ++It)
	{
		UStaticMeshComponent* Mesh = It->GetStaticMeshComponent();
		if (!Mesh)
		{
			continue;
		}
		// Keep/restore the CSG level shell as Static. CTF_USE_COMPLEX_AS_SIMPLE collision is only
		// valid for static shapes (Chaos); a prior lighting pass flipped the shell to Movable,
		// which made FindFloor miss (hit=0) while WorldStatic line traces still hit.
		// The shell has no UE lightmaps (force_no_precomputed_lighting; BioShock atlases not
		// imported). Do NOT flip it Movable to "fix" Play lighting — that re-breaks collision.
		// If the shell still looks wrong after camera exposure matches the repair PPV, use a
		// dual-mesh (Static collision proxy + Movable render mesh), not a mobility revert.
		const FString Label = It->GetActorLabel();
		const UStaticMesh* Asset = Mesh->GetStaticMesh();
		const FString AssetName = Asset ? Asset->GetName() : FString();
		const bool bCompiledWorld =
			Label.Equals(TEXT("compiled world"), ESearchCase::IgnoreCase)
			|| (AssetName.StartsWith(TEXT("Model")) && AssetName.Contains(TEXT("_")));
		if (bCompiledWorld)
		{
			if (Mesh->Mobility != EComponentMobility::Static)
			{
				Mesh->SetMobility(EComponentMobility::Static);
				++RestoredCompiledWorld;
			}
			continue;
		}
		if (Mesh->Mobility == EComponentMobility::Static)
		{
			Mesh->SetMobility(EComponentMobility::Movable);
			++Converted;
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

	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_SLICE_LIGHTING movable=%d restoreCompiled=%d fill=%d"),
		Converted,
		RestoredCompiledWorld,
		bHasFill ? 0 : 1);
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

APawn* AShockGameMode::SpawnDefaultPawnAtTransform_Implementation(
	AController* NewPlayer,
	const FTransform& SpawnTransform)
{
	// AGameModeBase hardcodes AdjustIfPossibleButDontSpawnIfColliding. After volume scales were
	// corrected, MedicalStart sits inside real BlockingVolume brushes and that path returns
	// nullptr — PostLogin then never arms -bioshockverifymovement and the process hangs.
	// SnapPawnToStart is the real placement; spawn must always succeed.
	UClass* PawnClass = GetDefaultPawnClassForController(NewPlayer);
	if (!PawnClass)
	{
		return nullptr;
	}
	UWorld* World = GetWorld();
	if (!World)
	{
		return nullptr;
	}
	FActorSpawnParameters Params;
	Params.Instigator = GetInstigator();
	Params.ObjectFlags |= RF_Transient;
	Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
	return World->SpawnActor<APawn>(PawnClass, SpawnTransform, Params);
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
	FHitResult SnapFloorHit;
	bool bSnapFloorValid = false;

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
			FCollisionQueryParams Params(SCENE_QUERY_STAT(BioShockSnapSpawn), false, Pawn);
			if (World->LineTraceSingleByChannel(SnapFloorHit, TraceStart, TraceEnd, ECC_WorldStatic, Params)
				&& SnapFloorHit.ImpactNormal.Z > 0.5f)
			{
				// Clearance above the line-hit: complex mesh + capsule radius can still report
				// start-penetrating at +2uu (FindFloor FloorDist≈-30). Sit a step higher.
				Loc.Z = SnapFloorHit.Location.Z + HalfHeight + 8.0f;
				bSnapFloorValid = true;
			}
		}
	}

	Pawn->SetActorLocationAndRotation(Loc, Rot, false, nullptr, ETeleportType::TeleportPhysics);

	if (ACharacter* Character = Cast<ACharacter>(Pawn))
	{
		if (UCharacterMovementComponent* Move = Character->GetCharacterMovement())
		{
			// Pull out of residual penetration so FindFloor can see a walkable surface. Without
			// this, CMC stays in MOVE_Falling / jammed and Velocity is zeroed every blocked step.
			FFindFloorResult FloorCheck;
			for (int32 Step = 0; Step < 24; ++Step)
			{
				Move->FindFloor(Character->GetActorLocation(), FloorCheck, false);
				if (FloorCheck.bWalkableFloor)
				{
					break;
				}
				const FVector Raised = Character->GetActorLocation() + FVector(0.0f, 0.0f, 10.0f);
				Character->SetActorLocation(Raised, false, nullptr, ETeleportType::TeleportPhysics);
			}
			Move->FindFloor(Character->GetActorLocation(), FloorCheck, false);
			if (FloorCheck.bWalkableFloor)
			{
				Move->CurrentFloor = FloorCheck;
				Move->SetMovementMode(MOVE_Walking);
			}
			else
			{
				Move->SetDefaultMovementMode();
			}
			Move->Velocity = FVector::ZeroVector;

			UE_LOG(
				LogTemp,
				Display,
				TEXT("BIOSHOCK_SNAP_FLOOR valid=%d blocking=%d mode=%d gravityZ=%.1f "
					 "findFloor hit=%d walkable=%d dist=%.1f locZ=%.2f"),
				bSnapFloorValid ? 1 : 0,
				SnapFloorHit.bBlockingHit ? 1 : 0,
				static_cast<int32>(Move->MovementMode),
				Move->GetGravityZ(),
				FloorCheck.bBlockingHit ? 1 : 0,
				FloorCheck.bWalkableFloor ? 1 : 0,
				FloorCheck.FloorDist,
				Character->GetActorLocation().Z);
		}
	}
}

void AShockGameMode::EquipStarterWeapon(AShockPlayer* Player)
{
	if (!Player)
	{
		return;
	}

	// Already has a starter loadout (re-possess / double PostLogin). Holster slot 0 is the
	// signal — GiveWeaponByDef does not auto-equip, so GetEquippedWeapon() is the wrong gate.
	if (Player->GetWeaponInSlot(0) != nullptr)
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
	Player->GiveWeaponByDef(TEXT("TommyGun"), 2);
	Player->GiveWeaponByDef(TEXT("Shotgun"), 3);
	Player->GiveWeaponByDef(TEXT("GrenadeLauncher"), 4);
	Player->GiveWeaponByDef(TEXT("ChemicalThrower"), 5);
	Player->GiveWeaponByDef(TEXT("Crossbow"), 6);
	Player->GiveWeapon(AShockResearchCamera::StaticClass(), 7);

	// The Wrench (slot 0) is the first weapon the player actually has in BioShock --
	// start equipped with it, not the Tommy Gun, matching what you'd really be
	// holding before finding any guns. Viewmodel meshes come from UShockWeaponDef::MeshAssetPath
	// via AShockWeapon::ApplyDef (skeletal guns + Wrench StaticMesh on StaticMesh component).
	// -bioshockstartslot=N (capture harness): equip a specific weapon slot instead of the Wrench,
	// so the screenshot pass can look at each viewmodel. 0..7 = Wrench/Pistol/TommyGun/Shotgun/
	// GrenadeLauncher/ChemicalThrower/Crossbow/Camera.
	int32 StartSlot = 0;
	FParse::Value(FCommandLine::Get(), TEXT("bioshockstartslot="), StartSlot);
	Player->SelectWeaponSlot(FMath::Clamp(StartSlot, 0, 7));

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
				ABaseShockAI::ApplyCombatSkeletalMesh(Body, MeshAsset, /*bDisableMeshCollision*/ true);
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

namespace
{
const TCHAR* MovementModeName(EMovementMode Mode)
{
	switch (Mode)
	{
	case MOVE_None:
		return TEXT("MOVE_None");
	case MOVE_Walking:
		return TEXT("MOVE_Walking");
	case MOVE_NavWalking:
		return TEXT("MOVE_NavWalking");
	case MOVE_Falling:
		return TEXT("MOVE_Falling");
	case MOVE_Swimming:
		return TEXT("MOVE_Swimming");
	case MOVE_Flying:
		return TEXT("MOVE_Flying");
	case MOVE_Custom:
		return TEXT("MOVE_Custom");
	default:
		return TEXT("MOVE_Unknown");
	}
}
} // namespace

void AShockGameMode::BeginVerifyMovement(AShockPlayer* Player)
{
	UWorld* World = GetWorld();
	if (!World || !Player)
	{
		UE_LOG(LogTemp, Error, TEXT("BIOSHOCK_MOVEMENT_FAIL reason=no_player"));
		FGenericPlatformMisc::RequestExit(false);
		return;
	}

	MovementVerifyPlayer = Player;
	MovementVerifyStartLoc = Player->GetActorLocation();
	bMovementVerifySawDisabled = Player->IsMovementDisabled();
	MovementVerifyModeStart = MOVE_None;
	const UCharacterMovementComponent* Move = Player->GetCharacterMovement();
	if (Move)
	{
		MovementVerifyModeStart = static_cast<uint8>(Move->MovementMode);
	}

	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_MOVEMENT_START x=%.2f y=%.2f z=%.2f mode=%s disabled=%d "
			 "updated=%d tick=%d role=%d maxspeed=%.0f"),
		MovementVerifyStartLoc.X,
		MovementVerifyStartLoc.Y,
		MovementVerifyStartLoc.Z,
		MovementModeName(static_cast<EMovementMode>(MovementVerifyModeStart)),
		bMovementVerifySawDisabled ? 1 : 0,
		(Move && Move->UpdatedComponent) ? 1 : 0,
		(Move && Move->IsComponentTickEnabled()) ? 1 : 0,
		static_cast<int32>(Player->GetLocalRole()),
		Move ? Move->GetMaxSpeed() : -1.0f);

	// UE5 FTimerManager ignores Rate<=0 (see InternalSetTimer InRate > 0.f). A rate of 0.0
	// never armed the drive timer. Use a short positive period so MoveForward reaches CMC.
	World->GetTimerManager().SetTimer(
		MovementVerifyDriveTimer,
		this,
		&AShockGameMode::TickVerifyMovementDrive,
		0.016f,
		true);
	World->GetTimerManager().SetTimer(
		MovementVerifyFinishTimer,
		this,
		&AShockGameMode::FinishVerifyMovement,
		2.5f,
		false);
}

void AShockGameMode::TickVerifyMovementDrive()
{
	AShockPlayer* Player = MovementVerifyPlayer.Get();
	if (!Player)
	{
		return;
	}
	if (Player->IsMovementDisabled())
	{
		bMovementVerifySawDisabled = true;
	}
	Player->DriveMoveForwardForVerify(1.0f);
}

void AShockGameMode::FinishVerifyMovement()
{
	if (UWorld* World = GetWorld())
	{
		World->GetTimerManager().ClearTimer(MovementVerifyDriveTimer);
	}

	AShockPlayer* Player = MovementVerifyPlayer.Get();
	if (!Player)
	{
		UE_LOG(LogTemp, Error, TEXT("BIOSHOCK_MOVEMENT_FAIL reason=player_gone"));
		FGenericPlatformMisc::RequestExit(false);
		return;
	}

	const FVector EndLoc = Player->GetActorLocation();
	const float Displacement = FVector::Dist(MovementVerifyStartLoc, EndLoc);
	EMovementMode ModeEnd = MOVE_None;
	FVector Velocity = FVector::ZeroVector;
	float GravityScale = 0.0f;
	bool bCmcActive = false;
	bool bHasController = Player->GetController() != nullptr;
	if (const UCharacterMovementComponent* Move = Player->GetCharacterMovement())
	{
		ModeEnd = Move->MovementMode;
		Velocity = Move->Velocity;
		GravityScale = Move->GravityScale;
		bCmcActive = Move->IsActive();
	}
	const EMovementMode ModeStart = static_cast<EMovementMode>(MovementVerifyModeStart);

	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_MOVEMENT_END start=(%.2f,%.2f,%.2f) end=(%.2f,%.2f,%.2f) "
			 "displacement=%.1f mode_start=%s mode_end=%s disabled_seen=%d "
			 "controller=%d cmc=%d gravity=%.2f vel=(%.1f,%.1f,%.1f)"),
		MovementVerifyStartLoc.X,
		MovementVerifyStartLoc.Y,
		MovementVerifyStartLoc.Z,
		EndLoc.X,
		EndLoc.Y,
		EndLoc.Z,
		Displacement,
		MovementModeName(ModeStart),
		MovementModeName(ModeEnd),
		bMovementVerifySawDisabled ? 1 : 0,
		bHasController ? 1 : 0,
		bCmcActive ? 1 : 0,
		GravityScale,
		Velocity.X,
		Velocity.Y,
		Velocity.Z);

	const bool bModeBroken =
		ModeStart == MOVE_None || ModeEnd == MOVE_None
		|| ModeStart == MOVE_Falling || ModeEnd == MOVE_Falling;
	const bool bNoMove = Displacement < 10.0f;
	if (bModeBroken || bNoMove || bMovementVerifySawDisabled || !bHasController || !bCmcActive)
	{
		FString Reason = TEXT("unknown");
		if (!bHasController)
		{
			Reason = TEXT("no_controller");
		}
		else if (!bCmcActive)
		{
			Reason = TEXT("cmc_inactive");
		}
		else if (bMovementVerifySawDisabled)
		{
			Reason = TEXT("movement_disabled");
		}
		else if (ModeStart == MOVE_Falling || ModeEnd == MOVE_Falling)
		{
			Reason = TEXT("move_falling");
		}
		else if (ModeStart == MOVE_None || ModeEnd == MOVE_None)
		{
			Reason = TEXT("move_none");
		}
		else
		{
			Reason = TEXT("no_displacement");
		}
		UE_LOG(
			LogTemp,
			Error,
			TEXT("BIOSHOCK_MOVEMENT_FAIL reason=%s displacement=%.1f mode_start=%s mode_end=%s"),
			*Reason,
			Displacement,
			MovementModeName(ModeStart),
			MovementModeName(ModeEnd));
	}
	else
	{
		UE_LOG(
			LogTemp,
			Display,
			TEXT("BIOSHOCK_MOVEMENT_OK displacement=%.1f mode_start=%s mode_end=%s"),
			Displacement,
			MovementModeName(ModeStart),
			MovementModeName(ModeEnd));
	}

	FGenericPlatformMisc::RequestExit(false);
}

void AShockGameMode::BeginVerifyWeaponTrack(AShockPlayer* Player)
{
	UWorld* World = GetWorld();
	if (!World || !Player)
	{
		UE_LOG(LogTemp, Error, TEXT("BIOSHOCK_WEAPON_TRACK_FAIL reason=no_player"));
		FGenericPlatformMisc::RequestExit(false);
		return;
	}

	WeaponTrackPlayer = Player;
	WeaponTrackSampleCount = 0;
	WeaponTrackAnimLength = 0.0f;
	WeaponTrackAnimName = NAME_None;

	// Starter loadout equips Wrench (slot 0); Pistol is slot 1 with FastReloadPistol (h8).
	if (!Player->SelectWeaponSlot(1))
	{
		UE_LOG(LogTemp, Error, TEXT("BIOSHOCK_WEAPON_TRACK_FAIL reason=select_pistol"));
		FGenericPlatformMisc::RequestExit(false);
		return;
	}

	AShockWeapon* Weapon = Player->GetEquippedWeapon();
	if (!Weapon || Weapon->GetWeaponDefName() != FName(TEXT("Pistol")))
	{
		UE_LOG(
			LogTemp,
			Error,
			TEXT("BIOSHOCK_WEAPON_TRACK_FAIL reason=no_pistol def=%s"),
			Weapon ? *Weapon->GetWeaponDefName().ToString() : TEXT("none"));
		FGenericPlatformMisc::RequestExit(false);
		return;
	}
	WeaponTrackWeapon = Weapon;

	// Mag must be below full with reserve left or Reload() refuses.
	Weapon->SetAmmoStateForVerify(FMath::Max(0, Weapon->GetMagazineSize() - 1), 30);

	WeaponTrackAnimLength = Player->GetViewHandsReloadPlayLengthForVerify();
	if (WeaponTrackAnimLength <= 0.0f)
	{
		UE_LOG(LogTemp, Error, TEXT("BIOSHOCK_WEAPON_TRACK_FAIL reason=no_reload_anim"));
		FGenericPlatformMisc::RequestExit(false);
		return;
	}

	if (!Weapon->Reload())
	{
		UE_LOG(LogTemp, Error, TEXT("BIOSHOCK_WEAPON_TRACK_FAIL reason=reload_failed"));
		FGenericPlatformMisc::RequestExit(false);
		return;
	}

	WeaponTrackAnimName = Player->GetPlayingViewHandsAnimationNameForVerify();
	const FTransform FirstXf = Weapon->GetActorTransform();
	WeaponTrackFirstLoc = FirstXf.GetLocation();
	WeaponTrackLastLoc = WeaponTrackFirstLoc;
	WeaponTrackMinLoc = WeaponTrackFirstLoc;
	WeaponTrackMaxLoc = WeaponTrackFirstLoc;
	WeaponTrackFirstRot = FirstXf.Rotator();
	WeaponTrackLastRot = WeaponTrackFirstRot;
	WeaponTrackSampleCount = 1;

	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_WEAPON_TRACK_START anim=%s len=%.3f socket=%s "
			 "x=%.2f y=%.2f z=%.2f pitch=%.1f yaw=%.1f roll=%.1f"),
		*WeaponTrackAnimName.ToString(),
		WeaponTrackAnimLength,
		*Player->GetActiveGripSocketForVerify().ToString(),
		WeaponTrackFirstLoc.X,
		WeaponTrackFirstLoc.Y,
		WeaponTrackFirstLoc.Z,
		WeaponTrackFirstRot.Pitch,
		WeaponTrackFirstRot.Yaw,
		WeaponTrackFirstRot.Roll);

	{
		const FVector AlignSocket = Player->GetActiveGripSocketWorldLocationForVerify();
		const FVector AlignBounds = Player->GetEquippedWeaponBoundsCenterForVerify();
		UE_LOG(
			LogTemp,
			Display,
			TEXT("BIOSHOCK_WEAPON_TRACK_ALIGN rootDist=%.2f boundsLateral=%.2f "
				 "socket=(%.1f,%.1f,%.1f) bounds=(%.1f,%.1f,%.1f)"),
			Player->GetGripToWeaponRootDistanceForVerify(),
			Player->GetGripToWeaponBoundsLateralDistanceForVerify(),
			AlignSocket.X,
			AlignSocket.Y,
			AlignSocket.Z,
			AlignBounds.X,
			AlignBounds.Y,
			AlignBounds.Z);
	}

	World->GetTimerManager().SetTimer(
		WeaponTrackSampleTimer,
		this,
		&AShockGameMode::TickVerifyWeaponTrackSample,
		0.1f,
		true);
	World->GetTimerManager().SetTimer(
		WeaponTrackFinishTimer,
		this,
		&AShockGameMode::FinishVerifyWeaponTrack,
		WeaponTrackAnimLength + 0.05f,
		false);
}

void AShockGameMode::TickVerifyWeaponTrackSample()
{
	AShockWeapon* Weapon = WeaponTrackWeapon.Get();
	if (!Weapon)
	{
		return;
	}
	const FTransform Xf = Weapon->GetActorTransform();
	const FVector Loc = Xf.GetLocation();
	WeaponTrackLastLoc = Loc;
	WeaponTrackLastRot = Xf.Rotator();
	WeaponTrackMinLoc.X = FMath::Min(WeaponTrackMinLoc.X, Loc.X);
	WeaponTrackMinLoc.Y = FMath::Min(WeaponTrackMinLoc.Y, Loc.Y);
	WeaponTrackMinLoc.Z = FMath::Min(WeaponTrackMinLoc.Z, Loc.Z);
	WeaponTrackMaxLoc.X = FMath::Max(WeaponTrackMaxLoc.X, Loc.X);
	WeaponTrackMaxLoc.Y = FMath::Max(WeaponTrackMaxLoc.Y, Loc.Y);
	WeaponTrackMaxLoc.Z = FMath::Max(WeaponTrackMaxLoc.Z, Loc.Z);
	++WeaponTrackSampleCount;

	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_WEAPON_TRACK_SAMPLE i=%d x=%.2f y=%.2f z=%.2f pitch=%.1f yaw=%.1f roll=%.1f"),
		WeaponTrackSampleCount,
		Loc.X,
		Loc.Y,
		Loc.Z,
		WeaponTrackLastRot.Pitch,
		WeaponTrackLastRot.Yaw,
		WeaponTrackLastRot.Roll);
}

void AShockGameMode::FinishVerifyWeaponTrack()
{
	if (UWorld* World = GetWorld())
	{
		World->GetTimerManager().ClearTimer(WeaponTrackSampleTimer);
	}

	// One last sample at finish so first/last span the full anim window.
	TickVerifyWeaponTrackSample();

	const FVector Range = WeaponTrackMaxLoc - WeaponTrackMinLoc;
	const float PosRange = Range.GetAbsMax();
	const float FirstLastDist = FVector::Dist(WeaponTrackFirstLoc, WeaponTrackLastLoc);

	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_WEAPON_TRACK_END samples=%d range=%.3f first_last=%.3f "
			 "first=(%.2f,%.2f,%.2f) last=(%.2f,%.2f,%.2f) anim=%s len=%.3f"),
		WeaponTrackSampleCount,
		PosRange,
		FirstLastDist,
		WeaponTrackFirstLoc.X,
		WeaponTrackFirstLoc.Y,
		WeaponTrackFirstLoc.Z,
		WeaponTrackLastLoc.X,
		WeaponTrackLastLoc.Y,
		WeaponTrackLastLoc.Z,
		*WeaponTrackAnimName.ToString(),
		WeaponTrackAnimLength);

	// Near-zero world motion while a reload plays => attachment is not tracking bone motion
	// (or something re-pins the grip every frame). Threshold is deliberately low; a live socket
	// follow during FastReloadPistol moves the gun by tens of units.
	if (PosRange < 1.0f)
	{
		UE_LOG(
			LogTemp,
			Error,
			TEXT("BIOSHOCK_WEAPON_TRACK_FAIL reason=static_weapon range=%.3f samples=%d"),
			PosRange,
			WeaponTrackSampleCount);
	}
	else
	{
		UE_LOG(
			LogTemp,
			Display,
			TEXT("BIOSHOCK_WEAPON_TRACK_OK samples=%d range=%.3f first_last=%.3f anim=%s"),
			WeaponTrackSampleCount,
			PosRange,
			FirstLastDist,
			*WeaponTrackAnimName.ToString());
	}

	FGenericPlatformMisc::RequestExit(false);
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
	EnsureSelectionUiForPlayer(PC);
}

void AShockGameMode::EnsureSelectionUiForPlayer(APlayerController* PC)
{
	if (!PC)
	{
		return;
	}
	if (!PlayerRadial)
	{
		PlayerRadial = CreateWidget<UShockRadialMenu>(PC, UShockRadialMenu::StaticClass());
	}
	if (PlayerRadial && !PlayerRadial->IsInViewport())
	{
		// Above HUD (0), below death overlay (100). Hit-test invisible while open — mouse aims hover.
		PlayerRadial->AddToViewport(10);
	}
	if (!PlayerSelect)
	{
		PlayerSelect = CreateWidget<UShockWeaponSelectScreen>(PC, UShockWeaponSelectScreen::StaticClass());
	}
	if (PlayerSelect && !PlayerSelect->IsInViewport())
	{
		PlayerSelect->AddToViewport(20);
	}
	if (!PlayerStatus)
	{
		PlayerStatus = CreateWidget<UShockStatusMenu>(PC, UShockStatusMenu::StaticClass());
	}
	if (PlayerStatus && !PlayerStatus->IsInViewport())
	{
		PlayerStatus->AddToViewport(30);
	}
	if (!PlayerPause)
	{
		PlayerPause = CreateWidget<UShockPauseMenu>(PC, UShockPauseMenu::StaticClass());
	}
	if (PlayerPause && !PlayerPause->IsInViewport())
	{
		PlayerPause->AddToViewport(40);
	}
}

void AShockGameMode::OpenWeaponRadial(AShockPlayer* Player)
{
	if (!Player)
	{
		return;
	}
	if (PlayerSelect && PlayerSelect->IsSelectOpen())
	{
		return;
	}
	if (PlayerStatus && PlayerStatus->IsStatusOpen())
	{
		return;
	}
	if (PlayerPause && PlayerPause->IsPauseOpen())
	{
		return;
	}
	APlayerController* PC = Cast<APlayerController>(Player->GetController());
	EnsureSelectionUiForPlayer(PC);
	if (!PlayerRadial)
	{
		return;
	}
	PlayerRadial->BindDisplayPlayer(Player);
	PlayerRadial->OpenRadial(EShockRadialMode::Weapon);
}

void AShockGameMode::OpenPlasmidRadial(AShockPlayer* Player)
{
	if (!Player)
	{
		return;
	}
	if (PlayerSelect && PlayerSelect->IsSelectOpen())
	{
		return;
	}
	if (PlayerStatus && PlayerStatus->IsStatusOpen())
	{
		return;
	}
	if (PlayerPause && PlayerPause->IsPauseOpen())
	{
		return;
	}
	APlayerController* PC = Cast<APlayerController>(Player->GetController());
	EnsureSelectionUiForPlayer(PC);
	if (!PlayerRadial)
	{
		return;
	}
	PlayerRadial->BindDisplayPlayer(Player);
	PlayerRadial->OpenRadial(EShockRadialMode::Plasmid);
}

void AShockGameMode::CloseRadial(bool bEquipHovered)
{
	if (PlayerRadial && PlayerRadial->IsRadialOpen())
	{
		PlayerRadial->CloseRadial(bEquipHovered);
	}
}

void AShockGameMode::StepRadialHover(int32 Delta)
{
	if (PlayerRadial && PlayerRadial->IsRadialOpen())
	{
		PlayerRadial->StepHoveredSegment(Delta);
	}
}

void AShockGameMode::ToggleWeaponSelect(AShockPlayer* Player)
{
	if (!Player)
	{
		return;
	}
	APlayerController* PC = Cast<APlayerController>(Player->GetController());
	EnsureSelectionUiForPlayer(PC);
	if (!PlayerSelect)
	{
		return;
	}
	if (PlayerSelect->IsSelectOpen())
	{
		PlayerSelect->CloseSelectScreen();
		return;
	}
	CloseRadial(false);
	PlayerSelect->BindDisplayPlayer(Player);
	PlayerSelect->OpenSelectScreen();
}

void AShockGameMode::ForceOpenRadialForCapture(AShockPlayer* Player)
{
	if (!Player)
	{
		return;
	}
	APlayerController* PC = Cast<APlayerController>(Player->GetController());
	EnsureSelectionUiForPlayer(PC);
	if (!PlayerRadial)
	{
		return;
	}
	PlayerRadial->BindDisplayPlayer(Player);
	PlayerRadial->ForceOpenForCapture(EShockRadialMode::Weapon);
}

void AShockGameMode::ToggleStatusMenu(AShockPlayer* Player)
{
	if (!Player)
	{
		return;
	}
	APlayerController* PC = Cast<APlayerController>(Player->GetController());
	EnsureSelectionUiForPlayer(PC);
	if (!PlayerStatus)
	{
		return;
	}
	if (PlayerStatus->IsStatusOpen())
	{
		PlayerStatus->CloseStatusMenu();
		return;
	}
	if (PlayerPause && PlayerPause->IsPauseOpen())
	{
		PlayerPause->ClosePauseMenu();
	}
	if (PlayerSelect && PlayerSelect->IsSelectOpen())
	{
		PlayerSelect->CloseSelectScreen();
	}
	CloseRadial(false);
	PlayerStatus->BindDisplayPlayer(Player);
	PlayerStatus->OpenStatusMenu();
}

void AShockGameMode::TogglePauseMenu(AShockPlayer* Player)
{
	if (!Player)
	{
		return;
	}
	APlayerController* PC = Cast<APlayerController>(Player->GetController());
	EnsureSelectionUiForPlayer(PC);
	if (!PlayerPause)
	{
		return;
	}
	// Esc while status is open closes status (status widget also handles Esc); don't open pause.
	if (PlayerStatus && PlayerStatus->IsStatusOpen())
	{
		PlayerStatus->CloseStatusMenu();
		return;
	}
	// Esc while select is open closes select (existing behaviour); don't open pause over it.
	if (PlayerSelect && PlayerSelect->IsSelectOpen())
	{
		PlayerSelect->CloseSelectScreen();
		return;
	}
	if (PlayerPause->IsPauseOpen())
	{
		PlayerPause->ClosePauseMenu();
		return;
	}
	CloseRadial(false);
	PlayerPause->BindDisplayPlayer(Player);
	PlayerPause->OpenPauseMenu();
}

void AShockGameMode::ForceOpenStatusForCapture(AShockPlayer* Player)
{
	if (!Player)
	{
		return;
	}
	APlayerController* PC = Cast<APlayerController>(Player->GetController());
	EnsureSelectionUiForPlayer(PC);
	if (!PlayerStatus)
	{
		return;
	}
	PlayerStatus->BindDisplayPlayer(Player);
	PlayerStatus->ForceOpenForCapture();
}

void AShockGameMode::ForceOpenPauseForCapture(AShockPlayer* Player)
{
	if (!Player)
	{
		return;
	}
	APlayerController* PC = Cast<APlayerController>(Player->GetController());
	EnsureSelectionUiForPlayer(PC);
	if (!PlayerPause)
	{
		return;
	}
	PlayerPause->BindDisplayPlayer(Player);
	PlayerPause->ForceOpenForCapture();
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
	if (!Pawn && NewPlayer
		&& (FParse::Param(FCommandLine::Get(), TEXT("bioshockverifymovement"))
			|| FParse::Param(FCommandLine::Get(), TEXT("bioshockverifyweapontrack"))
			|| FParse::Param(FCommandLine::Get(), TEXT("bioshockverifypossess"))
			|| FParse::Param(FCommandLine::Get(), TEXT("bioshockverifyencounter"))))
	{
		UE_LOG(LogTemp, Error, TEXT("BIOSHOCK_MOVEMENT_FAIL reason=no_pawn_spawned"));
		FGenericPlatformMisc::RequestExit(false);
		return;
	}
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
				if (FParse::Param(FCommandLine::Get(), TEXT("bioshockverifymovement")))
				{
					if (UWorld* World = GetWorld())
					{
						TWeakObjectPtr<AShockPlayer> WeakPlayer = Player;
						// Brief settle so CharacterMovement has a real mode after snap.
						World->GetTimerManager().SetTimer(
							MovementVerifyFinishTimer,
							FTimerDelegate::CreateLambda([this, WeakPlayer]()
							{
								if (WeakPlayer.IsValid())
								{
									BeginVerifyMovement(WeakPlayer.Get());
								}
								else
								{
									UE_LOG(LogTemp, Error, TEXT("BIOSHOCK_MOVEMENT_FAIL reason=player_gone"));
									FGenericPlatformMisc::RequestExit(false);
								}
							}),
							0.5f,
							false);
					}
					return;
				}
				if (FParse::Param(FCommandLine::Get(), TEXT("bioshockverifyweapontrack")))
				{
					if (UWorld* World = GetWorld())
					{
						TWeakObjectPtr<AShockPlayer> WeakPlayer = Player;
						// Let equip/viewmodel settle (same arming pattern as encounter).
						World->GetTimerManager().SetTimer(
							WeaponTrackFinishTimer,
							FTimerDelegate::CreateLambda([this, WeakPlayer]()
							{
								if (WeakPlayer.IsValid())
								{
									BeginVerifyWeaponTrack(WeakPlayer.Get());
								}
								else
								{
									UE_LOG(LogTemp, Error, TEXT("BIOSHOCK_WEAPON_TRACK_FAIL reason=player_gone"));
									FGenericPlatformMisc::RequestExit(false);
								}
							}),
							1.0f,
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

/**
 * Report which actor and material occupies a coarse grid of screen positions.
 *
 * A capture proves THAT something is wrong. It does not say which asset is responsible, and
 * guessing that from a thumbnail is expensive: a flat pale wedge in one corner was assumed to be
 * the compiled world's untextured section 0, and two rebuild-and-capture cycles later the frame
 * came back byte-identical, because it never was. Deprojecting the screen back into the world
 * answers the question directly.
 */
void AShockGameMode::ProbeViewmodel(APlayerController* PC, int32 ShotW, int32 ShotH)
{
	const AShockPlayer* Player = Cast<AShockPlayer>(PC ? PC->GetPawn() : nullptr);
	const USkeletalMeshComponent* Hands = Player ? Player->ViewHands : nullptr;
	const UCameraComponent* Camera = Player ? Player->FirstPersonCamera : nullptr;
	if (!Hands || !Camera)
	{
		UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_VIEWMODEL none"));
		return;
	}

	// Where the hands ACTUALLY are relative to the eye, in the camera's own frame: +X forward,
	// +Y right, +Z up. Reported because "the viewmodel is above the camera" has so far been tuned
	// by trying rotations and re-photographing, at roughly ten minutes a guess. The numbers below
	// say which axis is wrong and by how much, so the correction can be computed instead.
	const FTransform CameraToWorld = Camera->GetComponentTransform();
	const FBoxSphereBounds Bounds = Hands->Bounds;
	const FVector CentreLocal = CameraToWorld.InverseTransformPosition(Bounds.Origin);

	UE_LOG(
		LogTemp, Display,
		TEXT("BIOSHOCK_VIEWMODEL relLoc=%s relRot=%s boundsCentreCam=(%.1f,%.1f,%.1f) radius=%.1f"),
		*Hands->GetRelativeLocation().ToCompactString(),
		*Hands->GetRelativeRotation().ToCompactString(),
		CentreLocal.X, CentreLocal.Y, CentreLocal.Z, Bounds.SphereRadius);

	// And where that lands on screen, in the same 0..1 the grid below uses, so it can be read
	// against the shot directly. Behind the eye (X <= 0) is the interesting failure: it means the
	// mesh is not merely misplaced but out of the frustum entirely.
	FVector2D Screen = FVector2D::ZeroVector;
	const bool bOnScreen = PC->ProjectWorldLocationToScreen(Bounds.Origin, Screen);
	UE_LOG(
		LogTemp, Display,
		TEXT("BIOSHOCK_VIEWMODEL screen=%s forwardOfEye=%s"),
		bOnScreen && ShotW > 0 && ShotH > 0
			? *FString::Printf(TEXT("u=%.2f v=%.2f"), Screen.X / ShotW, Screen.Y / ShotH)
			: TEXT("offscreen"),
		CentreLocal.X > 0.0f ? TEXT("yes") : TEXT("NO — behind the camera"));

	// Whether the thing is even eligible to draw, separately from where it is. A rotation that
	// puts the bounds squarely in frame and still renders nothing is not a framing problem, and
	// guessing further rotations cannot distinguish "mis-aimed" from "not being drawn at all".
	UE_LOG(
		LogTemp, Display,
		TEXT("BIOSHOCK_VIEWMODEL visible=%d hiddenInGame=%d materials=%d bones=%d boxExtent=%s"),
		Hands->IsVisible() ? 1 : 0,
		Hands->bHiddenInGame ? 1 : 0,
		Hands->GetNumMaterials(),
		Hands->GetComponentSpaceTransforms().Num(),
		*Bounds.BoxExtent.ToCompactString());

	// The skeleton's REAL extent, from the posed bone transforms rather than from Bounds.
	// FBoxSphereBounds has disagreed with the socket twice on this mesh - it does not refresh
	// after SetRelativeRotation, and it reported the mesh topping out 81 units below the eye while
	// the grip socket (actual bone data) sat 28 below and plainly in frame. Bone positions cannot
	// be stale in that way, so this is the measurement to trust about where the arms are.
	{
		const TArray<FTransform>& BoneTransforms = Hands->GetComponentSpaceTransforms();
		if (BoneTransforms.Num() > 0)
		{
			FVector Min(FLT_MAX), Max(-FLT_MAX);
			int32 InFrontCount = 0;
			for (const FTransform& BoneTransform : BoneTransforms)
			{
				const FVector BoneCam = CameraToWorld.InverseTransformPosition(
					Hands->GetComponentTransform().TransformPosition(BoneTransform.GetLocation()));
				Min = Min.ComponentMin(BoneCam);
				Max = Max.ComponentMax(BoneCam);
				if (BoneCam.X > 0.0f)
				{
					++InFrontCount;
				}
			}
			UE_LOG(
				LogTemp, Display,
				TEXT("BIOSHOCK_VIEWMODEL boneCamMin=(%.1f,%.1f,%.1f) boneCamMax=(%.1f,%.1f,%.1f) "
					 "inFrontOfEye=%d/%d"),
				Min.X, Min.Y, Min.Z, Max.X, Max.Y, Max.Z, InFrontCount, BoneTransforms.Num());
		}
	}

	// The grip socket's own screen position. The bounds centre is an average over the whole mesh
	// and can sit in frame while every visible triangle is elsewhere; the socket is the one point
	// the framing maths actually aims, so this says whether the aim landed.
	if (Hands->DoesSocketExist(FName(TEXT("TommyGun"))))
	{
		const FVector SocketWorld = Hands->GetSocketLocation(FName(TEXT("TommyGun")));
		const FVector SocketCam = CameraToWorld.InverseTransformPosition(SocketWorld);
		FVector2D SocketScreen = FVector2D::ZeroVector;
		const bool bSocketOn = PC->ProjectWorldLocationToScreen(SocketWorld, SocketScreen);
		UE_LOG(
			LogTemp, Display,
			TEXT("BIOSHOCK_VIEWMODEL gripCam=(%.1f,%.1f,%.1f) gripScreen=%s"),
			SocketCam.X, SocketCam.Y, SocketCam.Z,
			bSocketOn && ShotW > 0 && ShotH > 0
				? *FString::Printf(TEXT("u=%.2f v=%.2f"), SocketScreen.X / ShotW, SocketScreen.Y / ShotH)
				: TEXT("offscreen"));
	}
}

void AShockGameMode::ProbeScreenGrid(APlayerController* PC, int32 ShotW, int32 ShotH)
{
	UWorld* World = PC ? PC->GetWorld() : nullptr;
	if (!World)
	{
		return;
	}

	ProbeViewmodel(PC, ShotW, ShotH);

	int32 Steps = 5;
	FParse::Value(FCommandLine::Get(), TEXT("bioshockprobesteps="), Steps);
	Steps = FMath::Clamp(Steps, 2, 12);

	FVector PlayerViewLocation = FVector::ZeroVector;
	FRotator PlayerViewRotation = FRotator::ZeroRotator;
	PC->GetPlayerViewPoint(PlayerViewLocation, PlayerViewRotation);
	if (!ScreenshotAimDelta.IsNearlyZero())
	{
		UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_PROBE aimDelta=%s (rays follow the capture, not the pawn)"),
			*ScreenshotAimDelta.ToCompactString());
	}

	FCollisionQueryParams Params(SCENE_QUERY_STAT(BioShockScreenProbe), true);
	Params.AddIgnoredActor(PC->GetPawn());
	// Both of these are opt-in: without them FaceIndex stays INDEX_NONE and FindCollisionUV fails,
	// so the probe would silently fall back to guessing exactly as before.
	Params.bReturnFaceIndex = true;
	Params.bTraceComplex = true;

	for (int32 Y = 0; Y < Steps; ++Y)
	{
		for (int32 X = 0; X < Steps; ++X)
		{
			// Sample cell centres so the grid never lands exactly on a screen edge.
			const float U = (X + 0.5f) / Steps;
			const float V = (Y + 0.5f) / Steps;
			const FVector2D Screen(U * ShotW, V * ShotH);

			FVector Origin = FVector::ZeroVector;
			FVector Direction = FVector::ForwardVector;
			if (!PC->DeprojectScreenPositionToWorld(Screen.X, Screen.Y, Origin, Direction))
			{
				continue;
			}

			// Deprojection uses the player's view; the shot may have been aimed elsewhere. The
			// capture camera is the player camera composed with this delta, so composing the same
			// delta onto each ray makes the probe describe the frame that was actually taken.
			if (!ScreenshotAimDelta.IsNearlyZero())
			{
				const FQuat Delta = (PlayerViewRotation + ScreenshotAimDelta).Quaternion()
					* PlayerViewRotation.Quaternion().Inverse();
				Direction = Delta.RotateVector(Direction);
			}

			// EVERY hit along the ray, not just the first. This level's compiled world carries
			// large invisible zone-portal planes across its openings, and they have collision, so
			// a single trace reports the portal and stops - it cannot see anything actually
			// rendered beyond it. That is not a rare case here: the portal is the first hit for
			// most of the left half of the frame.
			TArray<FHitResult> Hits;
			const FVector End = Origin + Direction * 100000.0f;
			if (!World->LineTraceMultiByChannel(Hits, Origin, End, ECC_Visibility, Params)
				|| Hits.Num() == 0)
			{
				UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_PROBE u=%.2f v=%.2f hit=none"), U, V);
				continue;
			}

			// Drop hits at zero distance. The camera stands inside several overlapping water
			// volumes here, so an unfiltered list spends every slot naming volumes that contain
			// the eye and never reaches the geometry actually on screen — which is how a green
			// bar in the corner of the frame got blamed on those volumes and survived being
			// "fixed". A volume you are inside is not a thing you are looking at.
			TArray<int32> Reportable;
			int32 ZeroDistanceHits = 0;
			for (int32 Index = 0; Index < Hits.Num(); ++Index)
			{
				if (Hits[Index].Distance < 1.0f)
				{
					++ZeroDistanceHits;
					continue;
				}
				Reportable.Add(Index);
				if (Reportable.Num() >= 4)
				{
					break;
				}
			}
			if (ZeroDistanceHits > 0)
			{
				UE_LOG(LogTemp, Display,
					TEXT("BIOSHOCK_PROBE u=%.2f v=%.2f enclosing=%d (camera is inside them)"),
					U, V, ZeroDistanceHits);
			}
			for (int32 HitIndex : Reportable)
			{
			const FHitResult& Hit = Hits[HitIndex];
			FString ActorName = Hit.GetActor() ? Hit.GetActor()->GetActorNameOrLabel() : TEXT("?");
			FString MaterialName = TEXT("none");
			FString MeshName = TEXT("none");
			if (UPrimitiveComponent* Comp = Hit.GetComponent())
			{
				if (UStaticMeshComponent* SM = Cast<UStaticMeshComponent>(Comp))
				{
					if (UStaticMesh* Mesh = SM->GetStaticMesh())
					{
						MeshName = Mesh->GetName();
					}
				}
				// Resolve the ONE material actually under the ray, via the face index. This is the
				// supported mapping from a collision hit to a render section; Hit.ElementIndex is a
				// physics element and means nothing here - reading it as a slot reported
				// "material=none" for a door whose material was correctly bound, and cost hours
				// chasing a binding bug that did not exist.
				int32 SectionIndex = INDEX_NONE;
				if (UMaterialInterface* HitMat =
						Comp->GetMaterialFromCollisionFaceIndex(Hit.FaceIndex, SectionIndex))
				{
					MaterialName = FString::Printf(
						TEXT("%s (section %d)"), *HitMat->GetName(), SectionIndex);
				}
				else
				{
					// Fall back to listing the slots. Less precise, but it never claims a specific
					// material that is not there.
					TArray<FString> Names;
					const int32 Count = Comp->GetNumMaterials();
					for (int32 Slot = 0; Slot < Count && Slot < 6; ++Slot)
					{
						UMaterialInterface* Mat = Comp->GetMaterial(Slot);
						Names.Add(Mat ? Mat->GetName() : TEXT("<empty>"));
					}
					if (Names.Num())
					{
						MaterialName = FString::Printf(
							TEXT("unresolved, slots [%d] %s"), Count,
							*FString::Join(Names, TEXT(", ")));
					}
				}
			}

			// MEASURE the texture coordinate rather than inferring it from how the surface looks.
			// A face whose UVs run to the hundreds samples a handful of texels across its whole
			// span and renders as flat untextured colour - indistinguishable by eye from a missing
			// material, which is precisely the confusion that has driven this hunt. Needs
			// bSupportUVFromHitResults; without it this returns false and prints uv=n/a rather
			// than a wrong number.
			FVector2D HitUV = FVector2D::ZeroVector;
			const bool bGotUV = UGameplayStatics::FindCollisionUV(Hit, 0, HitUV);

			UE_LOG(
				LogTemp, Display,
				TEXT("BIOSHOCK_PROBE u=%.2f v=%.2f [%d/%d] dist=%.0f actor=%s mesh=%s material=%s uv=%s"),
				U, V, HitIndex, Hits.Num(), Hit.Distance, *ActorName, *MeshName, *MaterialName,
				bGotUV ? *FString::Printf(TEXT("%.1f,%.1f"), HitUV.X, HitUV.Y) : TEXT("n/a"));
			}
		}
	}
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

		// -bioshockshotmove=F,R,U walks the capture from the PlayerStart along the view axes
		// (forward, right, up) before aiming. The slice spawn faces the airlock static meshes;
		// the compiled-world BSP walls are down the corridor and need the camera moved to them.
		{
			FString MoveStr;
			if (FParse::Value(FCommandLine::Get(), TEXT("bioshockshotmove="), MoveStr, false))
			{
				TArray<FString> P;
				MoveStr.ParseIntoArray(P, TEXT(","));
				if (P.Num() == 3)
				{
					const FRotator YawOnly(0.f, CamRot.Yaw, 0.f);
					CamLoc += YawOnly.RotateVector(FVector(
						FCString::Atof(*P[0]), FCString::Atof(*P[1]), FCString::Atof(*P[2])));
					UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_SHOT_MOVE %s -> %s"),
						*MoveStr, *CamLoc.ToCompactString());
				}
			}
		}

		// Aim the capture somewhere other than wherever the PlayerStart happens to face.
		// Every shot so far looks at the bathysphere airlock, which is all static meshes, so the
		// compiled world - the BSP shell that carries the reported "blown out, zoomed in" wall UVs
		// - has never actually been photographed. A UV scale cannot be judged from a number; it
		// has to be looked at against a wall of known size.
		// -bioshockshotabs=X,Y,Z puts the capture at an absolute world position, and
		// -bioshockshotlook=X,Y,Z aims it at a world point. The PlayerStart-relative move and
		// yaw/pitch cannot reach a specific BSP wall when the start sits in a static-mesh room
		// tens of metres from the compiled world; a commandlet that has loaded the level can
		// compute the pair and hand them here.
		{
			FString AbsStr;
			if (FParse::Value(FCommandLine::Get(), TEXT("bioshockshotabs="), AbsStr, false))
			{
				TArray<FString> P;
				AbsStr.ParseIntoArray(P, TEXT(","));
				if (P.Num() == 3)
				{
					CamLoc = FVector(FCString::Atof(*P[0]), FCString::Atof(*P[1]), FCString::Atof(*P[2]));
					UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_SHOT_ABS -> %s"), *CamLoc.ToCompactString());
				}
			}
			FString LookStr;
			if (FParse::Value(FCommandLine::Get(), TEXT("bioshockshotlook="), LookStr, false))
			{
				TArray<FString> P;
				LookStr.ParseIntoArray(P, TEXT(","));
				if (P.Num() == 3)
				{
					const FVector LookAt(FCString::Atof(*P[0]), FCString::Atof(*P[1]), FCString::Atof(*P[2]));
					CamRot = (LookAt - CamLoc).Rotation();
					UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_SHOT_LOOK %s -> %s"),
						*LookAt.ToCompactString(), *CamRot.ToCompactString());
				}
			}
		}

		float ShotYaw = 0.0f;
		float ShotPitch = 0.0f;
		if (FParse::Value(FCommandLine::Get(), TEXT("bioshockshotyaw="), ShotYaw))
		{
			CamRot.Yaw += ShotYaw;
		}
		if (FParse::Value(FCommandLine::Get(), TEXT("bioshockshotpitch="), ShotPitch))
		{
			CamRot.Pitch += ShotPitch;
		}
		// The probe grid deprojects through the PLAYER's view, so once the capture is aimed
		// somewhere else the two describe different scenes. Carry the delta so the probe can
		// rotate its rays to match; a probe that confidently describes a frame nobody took is
		// precisely the failure this harness exists to prevent.
		ScreenshotAimDelta = FRotator(ShotPitch, ShotYaw, 0.0f);
		if (!FMath::IsNearlyZero(ShotYaw) || !FMath::IsNearlyZero(ShotPitch))
		{
			UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_SHOT_AIM yaw+=%.1f pitch+=%.1f -> %s"),
				ShotYaw, ShotPitch, *CamRot.ToCompactString());
		}

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

			// -bioshockshotev=<stops> brightens the CAPTURE only, without touching the level.
			// The Medical lighting repair pins a dark manual exposure; a wall inspection shot
			// needs a couple of stops more to actually read the texture scale.
			float ShotEv = 0.0f;
			if (FParse::Value(FCommandLine::Get(), TEXT("bioshockshotev="), ShotEv)
				&& !FMath::IsNearlyZero(ShotEv))
			{
				Comp->PostProcessSettings.bOverride_AutoExposureBias = true;
				Comp->PostProcessSettings.AutoExposureBias += ShotEv;
				Comp->PostProcessBlendWeight = 1.0f;
				UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_SHOT_EV +%.1f"), ShotEv);
			}

			Comp->CaptureScene();
		}

		UKismetRenderingLibrary::ExportRenderTarget(
			CaptureWorld, Target, FPaths::GetPath(Path), FPaths::GetCleanFilename(Path));

		// -bioshockshothud also writes <name>_hud.png: the live HUD widget rasterised on its own
		// (mid-grey ground so transparent widget regions read). The SceneCapture2D above renders
		// only the 3D scene and never the Slate/UMG layer, so a UI phase can't be judged from the
		// plain capture.
		if (FParse::Param(FCommandLine::Get(), TEXT("bioshockshothud")))
		{
			EnsureHudForPlayer(PC);
			const bool bForceRadial = FParse::Param(FCommandLine::Get(), TEXT("bioshockshotradial"));
			const bool bForceStatus = FParse::Param(FCommandLine::Get(), TEXT("bioshockshotstatus"));
			const bool bForcePause = FParse::Param(FCommandLine::Get(), TEXT("bioshockshotpause"));
			if (AShockPlayer* ShotPlayer = Cast<AShockPlayer>(PC->GetPawn()))
			{
				if (bForceRadial)
				{
					ForceOpenRadialForCapture(ShotPlayer);
				}
				if (bForceStatus)
				{
					ForceOpenStatusForCapture(ShotPlayer);
				}
				if (bForcePause)
				{
					ForceOpenPauseForCapture(ShotPlayer);
				}
			}
			if (PlayerHud)
			{
				FWidgetRenderer WidgetRenderer(/*bUseGammaCorrection*/ true, /*bClearTarget*/ false);
				UTextureRenderTarget2D* HudRT = UKismetRenderingLibrary::CreateRenderTarget2D(
					CaptureWorld, ShotW, ShotH, RTF_RGBA8);
				HudRT->ClearColor = FLinearColor(0.25f, 0.25f, 0.25f, 1.0f);
				UKismetRenderingLibrary::ClearRenderTarget2D(
					CaptureWorld, HudRT, FLinearColor(0.25f, 0.25f, 0.25f, 1.0f));
				WidgetRenderer.DrawWidget(HudRT, PlayerHud->TakeWidget(), FVector2D(ShotW, ShotH), 0.0f);
				if (bForceRadial && PlayerRadial && PlayerRadial->IsRadialOpen())
				{
					WidgetRenderer.DrawWidget(
						HudRT, PlayerRadial->TakeWidget(), FVector2D(ShotW, ShotH), 0.0f);
				}
				if (bForceStatus && PlayerStatus && PlayerStatus->IsStatusOpen())
				{
					WidgetRenderer.DrawWidget(
						HudRT, PlayerStatus->TakeWidget(), FVector2D(ShotW, ShotH), 0.0f);
				}
				if (bForcePause && PlayerPause && PlayerPause->IsPauseOpen())
				{
					WidgetRenderer.DrawWidget(
						HudRT, PlayerPause->TakeWidget(), FVector2D(ShotW, ShotH), 0.0f);
				}
				FlushRenderingCommands();
				const FString HudPath = FPaths::GetPath(Path) / (FPaths::GetBaseFilename(Path) + TEXT("_hud.png"));
				UKismetRenderingLibrary::ExportRenderTarget(
					CaptureWorld, HudRT, FPaths::GetPath(HudPath), FPaths::GetCleanFilename(HudPath));
				UE_LOG(
					LogTemp,
					Display,
					TEXT("BIOSHOCK_SHOT_HUD path=%s radial=%d status=%d pause=%d"),
					*HudPath,
					(bForceRadial && PlayerRadial && PlayerRadial->IsRadialOpen()) ? 1 : 0,
					(bForceStatus && PlayerStatus && PlayerStatus->IsStatusOpen()) ? 1 : 0,
					(bForcePause && PlayerPause && PlayerPause->IsPauseOpen()) ? 1 : 0);
			}
			else
			{
				UE_LOG(LogTemp, Warning, TEXT("BIOSHOCK_SHOT_HUD no_hud_widget"));
			}
		}
		UE_LOG(
			LogTemp, Display, TEXT("BIOSHOCK_SCREENSHOT_REQUEST path=%s %dx%d"), *Path, ShotW, ShotH);

		// Name what is actually on screen. A picture shows THAT something is wrong; it does not say
		// which actor or material is responsible, and guessing at that from a thumbnail is how an
		// afternoon disappears. Deproject a coarse grid back into the world and report the hit.
		ProbeScreenGrid(PC, ShotW, ShotH);
		return;   // one more tick so the export lands before the world tears down
	}

	UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_SCREENSHOT_OK"));
	GetWorldTimerManager().ClearTimer(ScreenshotTimer);
	FGenericPlatformMisc::RequestExit(false);
}
