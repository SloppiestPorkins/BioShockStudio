#include "ShockAmmoPickup.h"

#include "ShockPlayer.h"
#include "ShockWeapon.h"
#include "Components/SphereComponent.h"
#include "EngineUtils.h"

AShockAmmoPickup::AShockAmmoPickup()
{
	PrimaryActorTick.bCanEverTick = false;

	Collision = CreateDefaultSubobject<USphereComponent>(TEXT("Collision"));
	SetRootComponent(Collision);
	Collision->InitSphereRadius(48.0f);
	Collision->SetCollisionEnabled(ECollisionEnabled::QueryOnly);
	Collision->SetCollisionObjectType(ECC_WorldDynamic);
	Collision->SetCollisionResponseToAllChannels(ECR_Ignore);
	Collision->SetCollisionResponseToChannel(ECC_Pawn, ECR_Overlap);
	Collision->SetGenerateOverlapEvents(true);
	Collision->OnComponentBeginOverlap.AddDynamic(this, &AShockAmmoPickup::OnOverlap);
}

void AShockAmmoPickup::TryGrantOverlappingPlayer()
{
	UWorld* World = GetWorld();
	if (!Collision || !World)
	{
		return;
	}

	Collision->UpdateOverlaps();
	TArray<AActor*> Overlapping;
	Collision->GetOverlappingActors(Overlapping, AShockPlayer::StaticClass());
	for (AActor* Actor : Overlapping)
	{
		GrantToPlayer(Cast<AShockPlayer>(Actor));
		if (!IsValid(this))
		{
			return;
		}
	}

	if (!Overlapping.IsEmpty())
	{
		return;
	}

	const FVector Center = Collision->GetComponentLocation();
	const float Radius = Collision->GetScaledSphereRadius() + 34.0f;
	for (TActorIterator<AShockPlayer> It(World); It; ++It)
	{
		AShockPlayer* Player = *It;
		if (!Player)
		{
			continue;
		}
		if (FVector::Dist(Center, Player->GetActorLocation()) <= Radius)
		{
			GrantToPlayer(Player);
			if (!IsValid(this))
			{
				return;
			}
		}
	}
}

void AShockAmmoPickup::GrantToPlayer(AShockPlayer* Player)
{
	if (!Player)
	{
		return;
	}

	AShockWeapon* Weapon = Player->GetEquippedWeapon();
	if (!Weapon)
	{
		return;
	}

	const int32 Before = Weapon->GetReserveAmmo();
	Weapon->AddReserveAmmo(PickupAmount);
	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_AMMO_PICKUP amount=%d reserve_before=%d reserve_after=%d"),
		PickupAmount,
		Before,
		Weapon->GetReserveAmmo());
	Destroy();
}

void AShockAmmoPickup::OnOverlap(
	UPrimitiveComponent* OverlappedComponent,
	AActor* OtherActor,
	UPrimitiveComponent* OtherComp,
	int32 OtherBodyIndex,
	bool bFromSweep,
	const FHitResult& SweepResult)
{
	(void)OverlappedComponent;
	(void)OtherComp;
	(void)OtherBodyIndex;
	(void)bFromSweep;
	(void)SweepResult;

	GrantToPlayer(Cast<AShockPlayer>(OtherActor));
}
