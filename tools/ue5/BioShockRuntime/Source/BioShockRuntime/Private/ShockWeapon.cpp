#include "ShockWeapon.h"

#include "ShockDamageLibrary.h"
#include "ShockPawn.h"
#include "Components/SkeletalMeshComponent.h"
#include "Engine/World.h"
#include "CollisionQueryParams.h"

AShockWeapon::AShockWeapon()
{
	PrimaryActorTick.bCanEverTick = false;
	Mesh = CreateDefaultSubobject<USkeletalMeshComponent>(TEXT("Mesh"));
	SetRootComponent(Mesh);
	Mesh->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	Mesh->SetCollisionResponseToAllChannels(ECR_Ignore);
	Mesh->SetCastShadow(false);
}

void AShockWeapon::ConfigureHitscan(float InDamage, float InRange)
{
	HitscanDamage = InDamage;
	HitscanRange = InRange;
}

bool AShockWeapon::FireAt(AActor* InstigatorActor, FVector Start, FVector Direction)
{
	UWorld* World = GetWorld();
	if (!World || Direction.IsNearlyZero())
	{
		return false;
	}

	++FireCount;
	LastHitPawn = nullptr;

	const FVector End = Start + Direction.GetSafeNormal() * HitscanRange;
	FHitResult Hit;
	FCollisionQueryParams Params(SCENE_QUERY_STAT(ShockWeaponFire), false, InstigatorActor);
	Params.AddIgnoredActor(this);

	FCollisionObjectQueryParams ObjectParams;
	ObjectParams.AddObjectTypesToQuery(ECC_Pawn);
	if (!World->LineTraceSingleByObjectType(Hit, Start, End, ObjectParams, Params))
	{
		return false;
	}

	AShockPawn* Victim = Cast<AShockPawn>(Hit.GetActor());
	if (!Victim)
	{
		return false;
	}

	UShockDamageLibrary::ApplyDamage(Victim, HitscanDamage, InstigatorActor, NAME_None);
	LastHitPawn = Victim;
	return true;
}
