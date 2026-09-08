#include "ShockEnemySpawner.h"

#include "BaseShockAI.h"
#include "ShockPlayer.h"
#include "ShockSecurityDeviceTypes.h"
#include "ShockTurret.h"
#include "Components/CapsuleComponent.h"
#include "Components/SceneComponent.h"
#include "Components/SphereComponent.h"
#include "Engine/World.h"
#include "EngineUtils.h"
#include "GameFramework/PlayerStart.h"
#include "NavMesh/NavMeshBoundsVolume.h"
#include "NavigationSystem.h"
#include "Misc/CommandLine.h"
#include "Misc/Parse.h"
#include "TimerManager.h"

namespace
{
const FVector2D SpawnOffsets[] = {
	FVector2D::ZeroVector,
	FVector2D(100.0f, 0.0f),
	FVector2D(-100.0f, 0.0f),
	FVector2D(0.0f, 100.0f),
	FVector2D(0.0f, -100.0f),
	FVector2D(200.0f, 0.0f),
	FVector2D(-200.0f, 0.0f),
	FVector2D(0.0f, 200.0f),
	FVector2D(0.0f, -200.0f),
};

void EnsureNavigationNear(UWorld* World, const FVector& Center)
{
	if (!World)
	{
		return;
	}
	const FName NavTag(TEXT("BioShockAuthoredSpawnerNav"));
	for (TActorIterator<ANavMeshBoundsVolume> It(World); It; ++It)
	{
		if (*It && It->Tags.Contains(NavTag)
			&& FVector::DistSquared2D(It->GetActorLocation(), Center) < FMath::Square(2500.0f))
		{
			return;
		}
	}

	FActorSpawnParameters Params;
	Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
	if (ANavMeshBoundsVolume* Volume = World->SpawnActor<ANavMeshBoundsVolume>(
			ANavMeshBoundsVolume::StaticClass(), Center, FRotator::ZeroRotator, Params))
	{
		Volume->Tags.Add(NavTag);
		Volume->SetActorScale3D(FVector(30.0f, 30.0f, 15.0f));
	}
	if (UNavigationSystemV1* Nav = UNavigationSystemV1::GetCurrent(World))
	{
		Nav->Build();
	}
}

bool SuppressForUnrelatedMovementVerify()
{
	return FParse::Param(FCommandLine::Get(), TEXT("bioshockverifymovement"))
		&& !FParse::Param(FCommandLine::Get(), TEXT("bioshockverifyenemies"));
}
}

AShockAggressorSpawner::AShockAggressorSpawner()
{
	PrimaryActorTick.bCanEverTick = false;

	ProximityTrigger = CreateDefaultSubobject<USphereComponent>(TEXT("ProximityTrigger"));
	SetRootComponent(ProximityTrigger);
	ProximityTrigger->SetSphereRadius(ProximityRadius);
	ProximityTrigger->SetCollisionProfileName(TEXT("Trigger"));
	ProximityTrigger->SetGenerateOverlapEvents(true);
	ProximityTrigger->OnComponentBeginOverlap.AddDynamic(
		this, &AShockAggressorSpawner::OnProximityBeginOverlap);
}

void AShockAggressorSpawner::Configure(
	FName InSourceKey,
	FName InSpawnerLabel,
	const TArray<FName>& InInitialArchetypes,
	const TArray<FName>& InRepopulationArchetypes,
	const TArray<FName>& InSpawnZones,
	FName InInitialPatrol,
	FName InRepopulationPatrol,
	float InProximityRadius)
{
	SourceKey = InSourceKey;
	SpawnerLabel = InSpawnerLabel;
	InitialArchetypes = InInitialArchetypes;
	RepopulationArchetypes = InRepopulationArchetypes;
	SpawnZones = InSpawnZones;
	InitialPatrol = InInitialPatrol;
	RepopulationPatrol = InRepopulationPatrol;
	ProximityRadius = FMath::Max(100.0f, InProximityRadius);
	if (ProximityTrigger)
	{
		ProximityTrigger->SetSphereRadius(ProximityRadius);
	}
}

void AShockAggressorSpawner::BeginPlay()
{
	Super::BeginPlay();
	if (SuppressForUnrelatedMovementVerify())
	{
		return;
	}
	// No spawn on BeginPlay. BioShock's opening splicers are script-driven (the level-start
	// sequence, the first scripted encounter) — spawning them immediately puts a hostile at the
	// bathysphere the instant the player arrives, which killed the player through the airlock
	// wall. Initial slots now fire only from a script (ShockActionSpawnAI / zone-enable);
	// repopulation stays proximity- or script-driven.
	if (!InitialArchetypes.IsEmpty() || !RepopulationArchetypes.IsEmpty())
	{
		GetWorldTimerManager().SetTimer(
			ProximityPollTimer,
			this,
			&AShockAggressorSpawner::CheckPlayerProximity,
			0.5f,
			true);
	}
}

bool AShockAggressorSpawner::FindGroundedSpawnLocation(
	UWorld* World,
	const FVector& Requested,
	float HeightAboveFloor,
	const AActor* Ignore,
	FVector& OutLocation)
{
	if (!World)
	{
		return false;
	}

	FCollisionQueryParams Query(SCENE_QUERY_STAT(ShockAuthoredSpawnerFloor), false, Ignore);
	for (const FVector2D& Offset : SpawnOffsets)
	{
		const FVector Base = Requested + FVector(Offset.X, Offset.Y, 0.0f);
		FHitResult FloorHit;
		if (!World->LineTraceSingleByChannel(
				FloorHit,
				Base + FVector(0.0f, 0.0f, 200.0f),
				Base - FVector(0.0f, 0.0f, 3000.0f),
				ECC_Visibility,
				Query)
			|| !FloorHit.bBlockingHit
			|| FloorHit.ImpactNormal.Z < 0.70f
			// A floor found more than 5 m below the authored marker is a pit / the abyss, not
			// the room this spawner belongs to — never drop a splicer into the void.
			|| FloorHit.ImpactPoint.Z < Requested.Z - 500.0f)
		{
			continue;
		}

		UNavigationSystemV1* Nav = UNavigationSystemV1::GetCurrent(World);
		FNavLocation NavLocation;
		if (Nav && Nav->ProjectPointToNavigation(
				FloorHit.ImpactPoint, NavLocation, FVector(300.0f, 300.0f, 300.0f)))
		{
			OutLocation = NavLocation.Location + FVector(0.0f, 0.0f, HeightAboveFloor);
			return true;
		}

		EnsureNavigationNear(World, FloorHit.ImpactPoint);
		// Match SpawnOneSliceEnemy: a walkable floor is mandatory, while runtime Recast tiles can
		// be unavailable for several frames. The grounded point remains safe and collision-tested.
		OutLocation = FloorHit.ImpactPoint + FVector(0.0f, 0.0f, HeightAboveFloor);
		UE_LOG(
			LogTemp,
			Warning,
			TEXT("BIOSHOCK_AUTHORED_SPAWN_NAV_UNAVAILABLE floor=%s"),
			*FloorHit.ImpactPoint.ToString());
		return true;
	}
	return false;
}

bool AShockAggressorSpawner::HasLiving(
	const TArray<TWeakObjectPtr<ABaseShockAI>>& Actors) const
{
	for (const TWeakObjectPtr<ABaseShockAI>& Weak : Actors)
	{
		if (const ABaseShockAI* AI = Weak.Get())
		{
			if (!AI->IsDead())
			{
				return true;
			}
		}
	}
	return false;
}

ABaseShockAI* AShockAggressorSpawner::SpawnOne(
	FName Archetype,
	FName Trigger,
	FName ForcedLabel)
{
	UWorld* World = GetWorld();
	if (!World || Archetype.IsNone())
	{
		return nullptr;
	}

	const float HalfHeight =
		GetDefault<ABaseShockAI>()->GetCapsuleComponent()->GetUnscaledCapsuleHalfHeight() + 2.0f;
	FVector SpawnLocation;
	if (!FindGroundedSpawnLocation(World, GetActorLocation(), HalfHeight, this, SpawnLocation))
	{
		UE_LOG(
			LogTemp,
			Warning,
			TEXT("BIOSHOCK_ENEMY_SPAWN_SKIP source=%s reason=floor_or_nav"),
			*SourceKey.ToString());
		return nullptr;
	}

	FActorSpawnParameters Params;
	Params.SpawnCollisionHandlingOverride =
		ESpawnActorCollisionHandlingMethod::AdjustIfPossibleButDontSpawnIfColliding;
	ABaseShockAI* AI = World->SpawnActor<ABaseShockAI>(
		ABaseShockAI::StaticClass(), SpawnLocation, GetActorRotation(), Params);
	if (!AI)
	{
		UE_LOG(
			LogTemp,
			Warning,
			TEXT("BIOSHOCK_ENEMY_SPAWN_SKIP source=%s reason=no_clear_capsule"),
			*SourceKey.ToString());
		return nullptr;
	}

	const FName Label = ForcedLabel.IsNone()
		? FName(*FString::Printf(TEXT("%s_Spawn%d"), *SpawnerLabel.ToString(), SpawnSerial++))
		: ForcedLabel;
	AI->ConfigureIdentity(Archetype, Label);
	AI->ApplyArchetypeLookup(Archetype);
	AI->EnsureHealthInitialized();
	if (UCapsuleComponent* Capsule = AI->GetCapsuleComponent())
	{
		Capsule->SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
		Capsule->SetCollisionObjectType(ECC_Pawn);
		Capsule->SetCollisionResponseToAllChannels(ECR_Ignore);
		Capsule->SetCollisionResponseToChannel(ECC_Pawn, ECR_Block);
		Capsule->SetCollisionResponseToChannel(ECC_Visibility, ECR_Block);
		Capsule->SetCollisionResponseToChannel(ECC_Camera, ECR_Block);
	}

	float PlayerDistance = -1.0f;
	if (AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World))
	{
#if WITH_EDITOR
		Player->SetActorLabel(TEXT("SlicePlayer"));
#endif
		AI->AddTargetToAttackOnSight(FName(TEXT("SlicePlayer")));
		// A proximity-spawned splicer must actually SEE the player before it engages — otherwise
		// it attacks (and lunges) through the wall it just spawned behind, which is what the
		// player experiences as "something is killing me and there is no enemy in sight". Only a
		// genuinely scripted spawn (the doctor-killer, a zone-enable encounter) arrives engaged.
		if (Trigger != FName(TEXT("proximity")))
		{
			AI->ScriptedAttackTarget(Player);
		}
		PlayerDistance = FVector::Dist(Player->GetActorLocation(), AI->GetActorLocation());
	}
#if WITH_EDITOR
	AI->SetActorLabel(Label.ToString());
#endif
	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_ENEMY_SPAWN source=%s archetype=%s trigger=%s alive=1 hostile=1 distance=%.1f"),
		*SourceKey.ToString(),
		*Archetype.ToString(),
		*Trigger.ToString(),
		PlayerDistance);
	return AI;
}

int32 AShockAggressorSpawner::SpawnArchetypes(
	const TArray<FName>& Archetypes,
	TArray<TWeakObjectPtr<ABaseShockAI>>& Live,
	FName Trigger,
	FName ForcedLabel)
{
	if (HasLiving(Live))
	{
		return 0;
	}
	Live.Reset();
	int32 Spawned = 0;
	for (int32 Index = 0; Index < Archetypes.Num(); ++Index)
	{
		const FName Label = (Index == 0) ? ForcedLabel : NAME_None;
		if (ABaseShockAI* AI = SpawnOne(Archetypes[Index], Trigger, Label))
		{
			Live.Add(AI);
			++Spawned;
		}
	}
	return Spawned;
}

void AShockAggressorSpawner::SpawnInitial()
{
	const int32 Spawned =
		SpawnArchetypes(InitialArchetypes, LiveInitial, FName(TEXT("immediate")));
	if (Spawned == 0 && !HasLiving(LiveInitial))
	{
		GetWorldTimerManager().SetTimer(
			InitialRetryTimer, this, &AShockAggressorSpawner::SpawnInitial, 3.0f, false);
	}
}

bool AShockAggressorSpawner::PlayerInOpeningGrace() const
{
	UWorld* World = GetWorld();
	if (!World)
	{
		return true;
	}
	// BioShock's opening beat (bathysphere -> the doctor scene) is entirely scripted; no free
	// splicer belongs near the arrival. Hold proximity spawning for a short window and while the
	// player is still within reach of a level start.
	if (World->GetTimeSeconds() < ProximityArmDelaySeconds)
	{
		return true;
	}
	const AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World);
	if (!Player)
	{
		return true;
	}
	for (TActorIterator<APlayerStart> It(World); It; ++It)
	{
		if (FVector::DistSquared(Player->GetActorLocation(), It->GetActorLocation())
			< FMath::Square(2600.0f))
		{
			return true;
		}
	}
	return false;
}

void AShockAggressorSpawner::CheckPlayerProximity()
{
	if (!bRepopulationEnabled || HasLiving(LiveRepopulation) || PlayerInOpeningGrace())
	{
		return;
	}
	if (const AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(GetWorld()))
	{
		if (FVector::DistSquared(Player->GetActorLocation(), GetActorLocation())
			<= FMath::Square(ProximityRadius))
		{
			SpawnRepopulation(FName(TEXT("proximity")));
		}
	}
}

int32 AShockAggressorSpawner::SpawnRepopulation(FName Trigger)
{
	if (!bRepopulationEnabled)
	{
		return 0;
	}
	return SpawnArchetypes(RepopulationArchetypes, LiveRepopulation, Trigger);
}

AActor* AShockAggressorSpawner::SpawnForScript(FName Archetype, FName SpawnedLabel)
{
	return SpawnOne(Archetype, FName(TEXT("script")), SpawnedLabel);
}

void AShockAggressorSpawner::SetRepopulationEnabled(bool bEnabled, bool bSpawnNow)
{
	bRepopulationEnabled = bEnabled;
	if (bEnabled && bSpawnNow)
	{
		// A script enabling this spawner's zone is the "game event" that brings the level's
		// authored population in — spawn the initial slot (once) as well as repopulation.
		if (!bInitialSpawned && !InitialArchetypes.IsEmpty())
		{
			bInitialSpawned = true;
			SpawnArchetypes(InitialArchetypes, LiveInitial, FName(TEXT("script-zone")));
		}
		SpawnRepopulation(FName(TEXT("script-zone")));
	}
}

bool AShockAggressorSpawner::HasZone(FName Zone) const
{
	return !Zone.IsNone() && SpawnZones.Contains(Zone);
}

bool AShockAggressorSpawner::MatchesLabel(FName Label) const
{
	return !Label.IsNone() && (SpawnerLabel == Label || SourceKey == Label || GetFName() == Label);
}

void AShockAggressorSpawner::OnProximityBeginOverlap(
	UPrimitiveComponent* OverlappedComponent,
	AActor* OtherActor,
	UPrimitiveComponent* OtherComponent,
	int32 OtherBodyIndex,
	bool bFromSweep,
	const FHitResult& SweepResult)
{
	(void)OverlappedComponent;
	(void)OtherComponent;
	(void)OtherBodyIndex;
	(void)bFromSweep;
	(void)SweepResult;
	if (Cast<AShockPlayer>(OtherActor) && !PlayerInOpeningGrace())
	{
		SpawnRepopulation(FName(TEXT("proximity")));
	}
}

AShockTurretSpawner::AShockTurretSpawner()
{
	PrimaryActorTick.bCanEverTick = false;
	USceneComponent* Root = CreateDefaultSubobject<USceneComponent>(TEXT("Root"));
	SetRootComponent(Root);
}

void AShockTurretSpawner::Configure(
	FName InSourceKey,
	FName InSpawnerLabel,
	FName InSpawnedTurretLabel,
	FName InTurretType,
	const TArray<FName>& InSpawnZones,
	bool bInScriptOnly,
	bool bInCanBeHacked,
	float InSightDistance)
{
	SourceKey = InSourceKey;
	SpawnerLabel = InSpawnerLabel;
	SpawnedTurretLabel = InSpawnedTurretLabel;
	TurretType = InTurretType;
	SpawnZones = InSpawnZones;
	bScriptOnly = bInScriptOnly;
	bCanBeHacked = bInCanBeHacked;
	SightDistance = InSightDistance > 0.0f ? InSightDistance : 1000.0f;
}

void AShockTurretSpawner::BeginPlay()
{
	Super::BeginPlay();
	if (SuppressForUnrelatedMovementVerify())
	{
		return;
	}
	if (!bScriptOnly)
	{
		// A few seconds in, not on the possess frame — and never while the player is standing
		// inside the turret's own sight range (it would open fire through the airlock wall).
		GetWorldTimerManager().SetTimer(
			InitialSpawnTimer, this, &AShockTurretSpawner::SpawnInitialTurret, 3.0f, false);
	}
}

void AShockTurretSpawner::SpawnInitialTurret()
{
	if (const AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(GetWorld()))
	{
		if (FVector::DistSquared(Player->GetActorLocation(), GetActorLocation())
			< FMath::Square(FMath::Max(SightDistance, 1500.0f)))
		{
			GetWorldTimerManager().SetTimer(
				InitialRetryTimer, this, &AShockTurretSpawner::SpawnInitialTurret, 3.0f, false);
			return;
		}
	}
	if (!SpawnTurret(FName(TEXT("immediate"))))
	{
		GetWorldTimerManager().SetTimer(
			InitialRetryTimer, this, &AShockTurretSpawner::SpawnInitialTurret, 3.0f, false);
	}
}

bool AShockTurretSpawner::MatchesLabel(FName Label) const
{
	return !Label.IsNone() && (SpawnerLabel == Label || SourceKey == Label || GetFName() == Label);
}

AShockTurret* AShockTurretSpawner::SpawnTurret(FName Trigger)
{
	if (AShockTurret* Existing = SpawnedTurret.Get())
	{
		if (Existing->IsDeviceOperational())
		{
			return Existing;
		}
	}

	UWorld* World = GetWorld();
	FVector SpawnLocation;
	if (!AShockAggressorSpawner::FindGroundedSpawnLocation(
			World, GetActorLocation(), 40.0f, this, SpawnLocation))
	{
		UE_LOG(
			LogTemp,
			Warning,
			TEXT("BIOSHOCK_TURRET_SPAWN_SKIP source=%s reason=floor_or_nav"),
			*SourceKey.ToString());
		return nullptr;
	}

	FActorSpawnParameters Params;
	Params.SpawnCollisionHandlingOverride =
		ESpawnActorCollisionHandlingMethod::AdjustIfPossibleButDontSpawnIfColliding;
	AShockTurret* Turret = World->SpawnActor<AShockTurret>(
		AShockTurret::StaticClass(), SpawnLocation, GetActorRotation(), Params);
	if (!Turret)
	{
		return nullptr;
	}
	const FName Label = SpawnedTurretLabel.IsNone() ? SpawnerLabel : SpawnedTurretLabel;
	Turret->SetDeviceLabel(Label);
	Turret->SetAllegiance(EShockDeviceAllegiance::Hostile);
	Turret->DetectionRange = SightDistance;
#if WITH_EDITOR
	Turret->SetActorLabel(Label.ToString());
#endif
	SpawnedTurret = Turret;
	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_TURRET_SPAWN source=%s trigger=%s hostile=1 hackable=%d"),
		*SourceKey.ToString(),
		*Trigger.ToString(),
		bCanBeHacked ? 1 : 0);
	return Turret;
}
