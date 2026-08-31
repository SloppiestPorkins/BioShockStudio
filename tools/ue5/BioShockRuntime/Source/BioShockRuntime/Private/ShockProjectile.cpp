#include "ShockProjectile.h"

#include "ShockDamageLibrary.h"
#include "ShockPawn.h"
#include "Components/SphereComponent.h"
#include "DrawDebugHelpers.h"
#include "Engine/World.h"
#include "GameFramework/ProjectileMovementComponent.h"

AShockProjectile::AShockProjectile()
{
	PrimaryActorTick.bCanEverTick = true;

	CollisionSphere = CreateDefaultSubobject<USphereComponent>(TEXT("CollisionSphere"));
	SetRootComponent(CollisionSphere);
	CollisionSphere->InitSphereRadius(8.0f);
	CollisionSphere->SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	CollisionSphere->SetCollisionObjectType(ECC_WorldDynamic);
	CollisionSphere->SetCollisionResponseToAllChannels(ECR_Block);
	CollisionSphere->SetCollisionResponseToChannel(ECC_Pawn, ECR_Overlap);
	CollisionSphere->SetGenerateOverlapEvents(true);
	CollisionSphere->OnComponentHit.AddDynamic(this, &AShockProjectile::OnProjectileHit);

	Movement = CreateDefaultSubobject<UProjectileMovementComponent>(TEXT("Movement"));
	Movement->UpdatedComponent = CollisionSphere;
	Movement->InitialSpeed = InitialSpeed;
	Movement->MaxSpeed = InitialSpeed;
	Movement->bRotationFollowsVelocity = true;
	Movement->ProjectileGravityScale = 0.0f;
	Movement->bShouldBounce = false;
}

void AShockProjectile::ConfigureFromWeapon(
	FName InWeaponName,
	float InDamage,
	float InImpactRadius,
	float InInitialSpeed,
	float InLifeSeconds,
	AActor* InInstigator,
	const FVector& LaunchDirection)
{
	SourceWeaponName = InWeaponName;
	Damage = InDamage;
	ImpactRadius = InImpactRadius;
	InitialSpeed = InInitialSpeed;
	LifeSeconds = InLifeSeconds;
	RemainingLife = InLifeSeconds;
	DamageInstigator = InInstigator;

	if (Movement)
	{
		Movement->InitialSpeed = InitialSpeed;
		Movement->MaxSpeed = InitialSpeed;
		Movement->Velocity = LaunchDirection.GetSafeNormal() * InitialSpeed;
	}

	if (CollisionSphere && InInstigator)
	{
		CollisionSphere->IgnoreActorWhenMoving(InInstigator, true);
	}
}

void AShockProjectile::OnProjectileHit(
	UPrimitiveComponent* HitComponent,
	AActor* OtherActor,
	UPrimitiveComponent* OtherComp,
	FVector NormalImpulse,
	const FHitResult& Hit)
{
	(void)HitComponent;
	(void)OtherComp;
	(void)NormalImpulse;

	if (bHasImpacted)
	{
		return;
	}

	const bool bDirectPawnHit = Cast<AShockPawn>(OtherActor) != nullptr;
	Detonate(Hit.ImpactPoint, bDirectPawnHit);
}

void AShockProjectile::Detonate(const FVector& ImpactPoint, bool bDirectHit)
{
	if (bHasImpacted)
	{
		return;
	}
	bHasImpacted = true;

	UWorld* World = GetWorld();
	if (!World)
	{
		Destroy();
		return;
	}

	int32 HitCount = 0;
	if (ImpactRadius > 0.0f)
	{
		HitCount = UShockDamageLibrary::ApplyRadialDamage(
			World,
			ImpactPoint,
			ImpactRadius,
			Damage,
			DamageInstigator.Get(),
			NAME_None,
			ImpactRadius * 0.77f);
	}
	else if (bDirectHit)
	{
		FCollisionQueryParams Params(SCENE_QUERY_STAT(ShockProjectileDirect), false, this);
		Params.AddIgnoredActor(this);
		if (DamageInstigator.IsValid())
		{
			Params.AddIgnoredActor(DamageInstigator.Get());
		}
		FCollisionObjectQueryParams ObjectParams;
		ObjectParams.AddObjectTypesToQuery(ECC_Pawn);
		FHitResult Hit;
		if (World->LineTraceSingleByObjectType(
				Hit,
				ImpactPoint - FVector(1.0f, 0.0f, 0.0f),
				ImpactPoint + FVector(1.0f, 0.0f, 0.0f),
				ObjectParams,
				Params))
		{
			if (UShockDamageLibrary::ApplyDamage(Hit.GetActor(), Damage, DamageInstigator.Get(), NAME_None) > 0.0f)
			{
				HitCount = 1;
			}
		}
	}

	DrawDebugSphere(World, ImpactPoint, FMath::Max(8.0f, ImpactRadius * 0.05f), 8, FColor::Orange, false, 0.25f);
	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_PROJECTILE weapon=%s radius=%.0f hit=%d"),
		*SourceWeaponName.ToString(),
		ImpactRadius,
		HitCount > 0 ? 1 : 0);

	if (Movement)
	{
		Movement->StopMovementImmediately();
		Movement->Deactivate();
	}
	Destroy();
}

void AShockProjectile::ExpireLifetime(float DeltaSeconds)
{
	if (LifeSeconds <= 0.0f)
	{
		return;
	}
	RemainingLife -= DeltaSeconds;
	if (RemainingLife <= 0.0f && !bHasImpacted)
	{
		Detonate(GetActorLocation(), false);
	}
}

void AShockProjectile::AdvanceForVerify(float DeltaSeconds)
{
	if (bHasImpacted || DeltaSeconds <= 0.0f)
	{
		return;
	}

	UWorld* World = GetWorld();
	if (!World || !CollisionSphere)
	{
		return;
	}

	const FVector Start = GetActorLocation();
	FVector Velocity = Movement ? Movement->Velocity : FVector::ZeroVector;
	if (Velocity.IsNearlyZero())
	{
		Velocity = GetActorForwardVector() * InitialSpeed;
	}
	const FVector End = Start + Velocity * DeltaSeconds;

	FHitResult Hit;
	FCollisionQueryParams Params(SCENE_QUERY_STAT(ShockProjectileVerify), false, this);
	Params.AddIgnoredActor(this);
	if (DamageInstigator.IsValid())
	{
		Params.AddIgnoredActor(DamageInstigator.Get());
	}

	bool bHit = World->SweepSingleByChannel(
		Hit,
		Start,
		End,
		FQuat::Identity,
		ECC_WorldStatic,
		FCollisionShape::MakeSphere(CollisionSphere->GetScaledSphereRadius()),
		Params);

	if (!bHit)
	{
		FCollisionObjectQueryParams ObjectParams;
		ObjectParams.AddObjectTypesToQuery(ECC_Pawn);
		bHit = World->SweepSingleByObjectType(
			Hit,
			Start,
			End,
			FQuat::Identity,
			ObjectParams,
			FCollisionShape::MakeSphere(CollisionSphere->GetScaledSphereRadius()),
			Params);
	}

	if (bHit)
	{
		SetActorLocation(Hit.Location);
		const bool bDirectPawnHit = Cast<AShockPawn>(Hit.GetActor()) != nullptr;
		Detonate(Hit.ImpactPoint, bDirectPawnHit);
		return;
	}

	SetActorLocation(End);
	if (Movement)
	{
		Movement->Velocity = Velocity;
	}
	ExpireLifetime(DeltaSeconds);
}
