#include "ShockConsumablePickup.h"

#include "ShockPlayer.h"
#include "ShockWeapon.h"
#include "Components/SphereComponent.h"

namespace
{
FName PickupKindTag(EShockPickupKind Kind)
{
	switch (Kind)
	{
	case EShockPickupKind::FirstAidKit:
		return FName(TEXT("FirstAidKit"));
	case EShockPickupKind::EveHypo:
		return FName(TEXT("EveHypo"));
	case EShockPickupKind::Money:
		return FName(TEXT("Money"));
	case EShockPickupKind::Ammo:
		return FName(TEXT("Ammo"));
	default:
		return NAME_None;
	}
}
}

AShockConsumablePickup::AShockConsumablePickup()
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
	Collision->OnComponentBeginOverlap.AddDynamic(this, &AShockConsumablePickup::OnOverlap);
}

bool AShockConsumablePickup::PickupForVerify(AShockPlayer* Player)
{
	if (!Player || Amount <= 0)
	{
		return false;
	}
	ApplyPickup(Player);
	if (IsValid(this))
	{
		DestroyAfterPickup();
	}
	return true;
}

void AShockConsumablePickup::ConfigureForVerify(
	uint8 Kind,
	int32 InAmount,
	FName InWeaponDefName)
{
	PickupKind = static_cast<EShockPickupKind>(Kind);
	Amount = InAmount;
	WeaponDefName = InWeaponDefName;
}

void AShockConsumablePickup::ApplyPickup(AShockPlayer* Player)
{
	if (!Player || Amount <= 0)
	{
		return;
	}

	switch (PickupKind)
	{
	case EShockPickupKind::FirstAidKit:
		Player->AddStackToInventory(FName(TEXT("FirstAidKit")), Amount);
		break;
	case EShockPickupKind::EveHypo:
		Player->AddStackToInventory(FName(TEXT("EveHypo")), Amount);
		break;
	case EShockPickupKind::Money:
		Player->AddMoney(Amount);
		break;
	case EShockPickupKind::Ammo:
	{
		AShockWeapon* Weapon = Player->GetEquippedWeapon();
		if (!WeaponDefName.IsNone())
		{
			for (int32 Slot = 0; Slot < 8; ++Slot)
			{
				if (AShockWeapon* SlotWeapon = Player->GetWeaponInSlot(Slot))
				{
					if (SlotWeapon->GetWeaponDefName() == WeaponDefName)
					{
						Weapon = SlotWeapon;
						break;
					}
				}
			}
		}
		if (Weapon)
		{
			Weapon->AddReserveAmmo(Amount);
		}
		break;
	}
	default:
		break;
	}

	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_PICKUP kind=%s amount=%d"),
		*PickupKindTag(PickupKind).ToString(),
		Amount);
}

void AShockConsumablePickup::DestroyAfterPickup()
{
	Destroy();
}

void AShockConsumablePickup::OnOverlap(
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

	if (AShockPlayer* Player = Cast<AShockPlayer>(OtherActor))
	{
		ApplyPickup(Player);
		if (IsValid(this))
		{
			DestroyAfterPickup();
		}
	}
}
