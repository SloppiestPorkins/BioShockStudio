#include "ShockConsumablePickup.h"

#include "Components/SphereComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/StaticMesh.h"
#include "ShockPlasmid.h"
#include "ShockPlayer.h"
#include "ShockWeapon.h"

namespace
{
FName PickupKindTag(EShockPickupKind Kind)
{
	switch (Kind)
	{
	case EShockPickupKind::FirstAidKit: return FName(TEXT("FirstAidKit"));
	case EShockPickupKind::EveHypo: return FName(TEXT("EveHypo"));
	case EShockPickupKind::Money: return FName(TEXT("Money"));
	case EShockPickupKind::Ammo: return FName(TEXT("Ammo"));
	case EShockPickupKind::Adam: return FName(TEXT("Adam"));
	case EShockPickupKind::Item: return FName(TEXT("Item"));
	case EShockPickupKind::Weapon: return FName(TEXT("Weapon"));
	case EShockPickupKind::Plasmid: return FName(TEXT("Plasmid"));
	case EShockPickupKind::Diary: return FName(TEXT("Diary"));
	default: return NAME_None;
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

	Mesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Mesh"));
	Mesh->SetupAttachment(Collision);
	Mesh->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	Mesh->SetCastShadow(false);
}

void AShockConsumablePickup::SetPickupMesh(UStaticMesh* InMesh)
{
	if (Mesh && InMesh)
	{
		Mesh->SetStaticMesh(InMesh);
	}
}

bool AShockConsumablePickup::TryCollect(AShockPlayer* Player)
{
	if (!Player)
	{
		return false;
	}
	if (!ApplyPickup(Player))
	{
		return false;
	}
	if (IsValid(this))
	{
		DestroyAfterPickup();
	}
	return true;
}

bool AShockConsumablePickup::PickupForVerify(AShockPlayer* Player)
{
	return TryCollect(Player);
}

void AShockConsumablePickup::ConfigureForVerify(uint8 Kind, int32 InAmount, FName InWeaponDefName)
{
	PickupKind = static_cast<EShockPickupKind>(Kind);
	Amount = InAmount;
	WeaponDefName = InWeaponDefName;
}

void AShockConsumablePickup::ConfigurePickup(
	uint8 Kind,
	int32 InAmount,
	FName InWeaponDefName,
	FName InItemClass,
	FName InPlasmidName,
	FName InDiaryId,
	bool bInRequiresInteract)
{
	PickupKind = static_cast<EShockPickupKind>(Kind);
	Amount = InAmount;
	WeaponDefName = InWeaponDefName;
	ItemClass = InItemClass;
	PlasmidName = InPlasmidName;
	DiaryId = InDiaryId;
	bRequiresInteract = bInRequiresInteract;
}

bool AShockConsumablePickup::ApplyPickup(AShockPlayer* Player)
{
	if (!Player)
	{
		return false;
	}
	const int32 Qty = FMath::Max(1, Amount);

	switch (PickupKind)
	{
	case EShockPickupKind::FirstAidKit:
		Player->AddStackToInventory(FName(TEXT("FirstAidKit")), Qty);
		break;
	case EShockPickupKind::EveHypo:
		Player->AddStackToInventory(FName(TEXT("EveHypo")), Qty);
		break;
	case EShockPickupKind::Money:
		Player->AddMoney(Qty);
		break;
	case EShockPickupKind::Adam:
		Player->AddAdam(Qty);
		break;
	case EShockPickupKind::Item:
		Player->AddStackToInventory(ItemClass.IsNone() ? FName(TEXT("Item")) : ItemClass, Qty);
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
			Weapon->AddReserveAmmo(Qty);
		}
		break;
	}
	case EShockPickupKind::Weapon:
	{
		if (WeaponDefName.IsNone())
		{
			return false;
		}
		// First free slot, else slot 1.
		int32 Slot = 1;
		for (int32 S = 0; S < 8; ++S)
		{
			if (!Player->GetWeaponInSlot(S))
			{
				Slot = S;
				break;
			}
		}
		if (AShockWeapon* Given = Player->GiveWeaponByDef(WeaponDefName, Slot))
		{
			Given->AddReserveAmmo(Qty > 1 ? Qty : 40);
		}
		break;
	}
	case EShockPickupKind::Plasmid:
	{
		const TSubclassOf<UShockPlasmid> Cls = UShockPlasmid::ResolvePlasmidClass(PlasmidName);
		if (!Cls)
		{
			return false;
		}
		Player->GrantOwnedPlasmid(Cls);
		break;
	}
	case EShockPickupKind::Diary:
		Player->AddStackToInventory(
			FName(*FString::Printf(TEXT("AudioDiary_%s"), *DiaryId.ToString())), 1);
		UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_DIARY id=%s"), *DiaryId.ToString());
		break;
	default:
		return false;
	}

	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_PICKUP kind=%s amount=%d item=%s"),
		*PickupKindTag(PickupKind).ToString(),
		Qty,
		WeaponDefName.IsNone() ? *ItemClass.ToString() : *WeaponDefName.ToString());
	return true;
}

void AShockConsumablePickup::DestroyAfterPickup()
{
	Destroy();
}

void AShockConsumablePickup::OnOverlap(
	UPrimitiveComponent* /*OverlappedComponent*/,
	AActor* OtherActor,
	UPrimitiveComponent* /*OtherComp*/,
	int32 /*OtherBodyIndex*/,
	bool /*bFromSweep*/,
	const FHitResult& /*SweepResult*/)
{
	if (bRequiresInteract)
	{
		return;
	}
	if (AShockPlayer* Player = Cast<AShockPlayer>(OtherActor))
	{
		TryCollect(Player);
	}
}
