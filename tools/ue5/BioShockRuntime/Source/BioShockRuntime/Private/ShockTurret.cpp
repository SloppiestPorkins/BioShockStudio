#include "ShockTurret.h"

#include "BaseShockAI.h"
#include "ShockDamageLibrary.h"
#include "ShockPawn.h"
#include "ShockPlayer.h"
#include "ShockScriptSubsystem.h"
#include "ShockWeapon.h"
#include "Components/StaticMeshComponent.h"
#include "DrawDebugHelpers.h"
#include "Engine/StaticMesh.h"
#include "Engine/World.h"
#include "EngineUtils.h"
#include "CollisionQueryParams.h"
#include "UObject/ConstructorHelpers.h"

AShockTurret::AShockTurret()
{
	Allegiance = EShockDeviceAllegiance::Hostile;

	BarrelMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("BarrelMesh"));
	BarrelMesh->SetupAttachment(RootMesh);
	BarrelMesh->SetCollisionEnabled(ECollisionEnabled::NoCollision);

	static ConstructorHelpers::FObjectFinder<UStaticMesh> CylinderMesh(
		TEXT("/Engine/BasicShapes/Cylinder.Cylinder"));
	if (CylinderMesh.Succeeded())
	{
		BarrelMesh->SetStaticMesh(CylinderMesh.Object);
		BarrelMesh->SetRelativeLocation(FVector(55.0f, 0.0f, 0.0f));
		BarrelMesh->SetRelativeRotation(FRotator(0.0f, 0.0f, 90.0f));
		BarrelMesh->SetRelativeScale3D(FVector(0.15f, 0.15f, 0.5f));
	}
}

void AShockTurret::BeginPlay()
{
	Super::BeginPlay();
	EnsureWeapon();
	IdleSweepYaw = GetActorRotation().Yaw;
}

void AShockTurret::EnsureWeapon()
{
	if (TurretWeapon)
	{
		return;
	}

	UWorld* World = GetWorld();
	if (!World)
	{
		return;
	}

	FActorSpawnParameters Params;
	Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
	TurretWeapon = World->SpawnActor<AShockWeapon>(AShockWeapon::StaticClass(), GetActorLocation(), GetActorRotation(), Params);
	if (TurretWeapon)
	{
		TurretWeapon->ConfigureHitscan(HitscanDamage, HitscanRange);
		TurretWeapon->SetEnforceAmmo(false);
	}
}

void AShockTurret::TickDevice(float DeltaSeconds)
{
	if (!IsDeviceOperational())
	{
		return;
	}

	if (FireCooldownRemaining > 0.0f)
	{
		FireCooldownRemaining -= DeltaSeconds;
	}

	if (AShockPawn* Target = FindBestTarget())
	{
		UpdateAimToward(Target->GetActorLocation(), DeltaSeconds);
		if (FireCooldownRemaining <= 0.0f && CanDetectActor(Target))
		{
			TryFireAt(Target);
			FireCooldownRemaining = FireInterval;
		}
	}
	else
	{
		IdleSweep(DeltaSeconds);
	}
}

AShockPawn* AShockTurret::FindBestTarget() const
{
	UWorld* World = GetWorld();
	if (!World)
	{
		return nullptr;
	}

	AShockPawn* Best = nullptr;
	float BestDistSq = MAX_FLT;
	const FVector Origin = GetActorLocation();

	for (TActorIterator<AShockPawn> It(World); It; ++It)
	{
		AShockPawn* Pawn = *It;
		if (!Pawn || !IsOpposingSide(Pawn) || !CanDetectActor(Pawn))
		{
			continue;
		}

		const float DistSq = FVector::DistSquared(Origin, Pawn->GetActorLocation());
		if (DistSq < BestDistSq)
		{
			BestDistSq = DistSq;
			Best = Pawn;
		}
	}
	return Best;
}

void AShockTurret::UpdateAimToward(const FVector& WorldLocation, float DeltaSeconds)
{
	const FVector ToTarget = WorldLocation - GetActorLocation();
	if (ToTarget.IsNearlyZero())
	{
		return;
	}

	const FRotator Desired = ToTarget.Rotation();
	FRotator Current = GetActorRotation();
	Current.Yaw = FMath::FixedTurn(Current.Yaw, Desired.Yaw, IdleSweepYawRate * DeltaSeconds);
	Current.Pitch = FMath::FixedTurn(Current.Pitch, Desired.Pitch, IdleSweepYawRate * DeltaSeconds);
	SetActorRotation(Current);
}

void AShockTurret::IdleSweep(float DeltaSeconds)
{
	IdleSweepYaw += IdleSweepYawRate * DeltaSeconds;
	SetActorRotation(FRotator(0.0f, IdleSweepYaw, 0.0f));
}

void AShockTurret::TryFireAt(AShockPawn* Target)
{
	if (!Target)
	{
		return;
	}

	EnsureWeapon();
	const FVector Muzzle = BarrelMesh ? BarrelMesh->GetComponentLocation() : GetActorLocation();
	FVector Direction = Target->GetActorLocation() - Muzzle;
	if (Direction.IsNearlyZero())
	{
		return;
	}

	if (TurretWeapon)
	{
		TurretWeapon->AdvanceFireRateClockForVerify(FireInterval);
		if (TurretWeapon->FireAt(this, Muzzle, Direction))
		{
			++FireCount;
			if (UShockScriptSubsystem* Sub = UShockScriptSubsystem::Get(GetWorld()))
			{
				const FString Src = UShockScriptSubsystem::ResolveMessageSourceLabel(this);
				if (!Src.IsEmpty())
				{
					Sub->DispatchMessageLogged(FName(TEXT("MessageAIWeaponFired")), Src);
				}
			}
		}
		return;
	}

	UWorld* World = GetWorld();
	if (!World)
	{
		return;
	}

	const FVector NormDir = Direction.GetSafeNormal();
	const FVector End = Muzzle + NormDir * HitscanRange;
	FHitResult Hit;
	FCollisionQueryParams Params(SCENE_QUERY_STAT(ShockTurretFire), false, this);
	FCollisionObjectQueryParams ObjectParams;
	ObjectParams.AddObjectTypesToQuery(ECC_Pawn);
	const bool bHit =
		World->LineTraceSingleByObjectType(Hit, Muzzle, End, ObjectParams, Params);
	bool bPawnHit = false;
	if (bHit)
	{
		if (AShockPawn* Victim = Cast<AShockPawn>(Hit.GetActor()))
		{
			UShockDamageLibrary::ApplyDamage(Victim, HitscanDamage, this, NAME_None);
			bPawnHit = true;
			++FireCount;
			if (UShockScriptSubsystem* Sub = UShockScriptSubsystem::Get(World))
			{
				const FString Src = UShockScriptSubsystem::ResolveMessageSourceLabel(this);
				if (!Src.IsEmpty())
				{
					Sub->DispatchMessageLogged(FName(TEXT("MessageAIWeaponFired")), Src);
				}
			}
		}
	}
	PlayTurretFireFeedback(Muzzle, bHit ? Hit.ImpactPoint : End, bPawnHit);
}

void AShockTurret::PlayTurretFireFeedback(const FVector& Muzzle, const FVector& End, bool bPawnHit)
{
	if (UWorld* World = GetWorld())
	{
		DrawDebugLine(World, Muzzle, End, FColor(255, 220, 150), false, 0.05f, 0, 1.5f);
		if (bPawnHit)
		{
			DrawDebugSphere(World, End, 4.0f, 8, FColor(255, 40, 40), false, 0.15f);
		}
	}
}
