#include "ShockSearchableContainer.h"

#include "Components/SphereComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/StaticMesh.h"
#include "UObject/ConstructorHelpers.h"
#include "ShockPlayer.h"

AShockSearchableContainer::AShockSearchableContainer()
{
	PrimaryActorTick.bCanEverTick = false;

	Reach = CreateDefaultSubobject<USphereComponent>(TEXT("Reach"));
	SetRootComponent(Reach);
	Reach->InitSphereRadius(120.0f);
	Reach->SetCollisionEnabled(ECollisionEnabled::QueryOnly);
	Reach->SetCollisionObjectType(ECC_WorldDynamic);
	Reach->SetCollisionResponseToAllChannels(ECR_Ignore);
	Reach->SetCollisionResponseToChannel(ECC_Visibility, ECR_Block);
	Reach->SetCollisionResponseToChannel(ECC_Pawn, ECR_Overlap);

	Mesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Mesh"));
	Mesh->SetupAttachment(Reach);
	Mesh->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	Mesh->SetCastShadow(false);

	// Small marker until the real container/corpse meshes are imported.
	static ConstructorHelpers::FObjectFinder<UStaticMesh> MarkerMesh(
		TEXT("/Engine/BasicShapes/Sphere.Sphere"));
	if (MarkerMesh.Succeeded())
	{
		Mesh->SetStaticMesh(MarkerMesh.Object);
	}
	Mesh->SetRelativeScale3D(FVector(0.12f));
}

void AShockSearchableContainer::ConfigureContainer(
	FName InLabel,
	int32 InMoneyMin,
	int32 InMoneyMax,
	FName InItemClass,
	int32 InItemAmount)
{
	ScriptLabel = InLabel;
	LootMoneyMin = FMath::Max(0, InMoneyMin);
	LootMoneyMax = FMath::Max(LootMoneyMin, InMoneyMax);
	LootItemClass = InItemClass;
	LootItemAmount = FMath::Max(1, InItemAmount);
#if WITH_EDITOR
	if (!InLabel.IsNone())
	{
		SetActorLabel(InLabel.ToString());
	}
#endif
}

void AShockSearchableContainer::SetContainerMesh(UStaticMesh* InMesh)
{
	if (!Mesh)
	{
		return;
	}
	if (InMesh)
	{
		Mesh->SetStaticMesh(InMesh);
		Mesh->SetRelativeScale3D(FVector(1.0f));
		Mesh->SetVisibility(true);
		return;
	}
	// A corpse / booty stash has no mesh of its own — the ragdoll body (or the world prop) is a
	// separate actor. Hide the marker; the w10 interaction trace + "Press F to search" prompt is
	// how the player finds it.
	Mesh->SetStaticMesh(nullptr);
	Mesh->SetVisibility(false);
}

bool AShockSearchableContainer::PlaceItemInSlot(
	int32 Slot,
	FName ItemClass,
	int32 StackSize,
	bool bOverwrite)
{
	if (Slot < 0 || ItemClass.IsNone() || StackSize <= 0 || bSearched)
	{
		return false;
	}
	if (FShockContainerSlot* Existing = ScriptedSlots.Find(Slot))
	{
		if (!bOverwrite && Existing->ItemClass != ItemClass)
		{
			return false;
		}
		if (!bOverwrite)
		{
			Existing->StackSize += StackSize;
			return true;
		}
	}
	FShockContainerSlot& Entry = ScriptedSlots.FindOrAdd(Slot);
	Entry.ItemClass = ItemClass;
	Entry.StackSize = StackSize;
	return true;
}

FName AShockSearchableContainer::GetSlotItemClass(int32 Slot) const
{
	if (const FShockContainerSlot* Entry = ScriptedSlots.Find(Slot))
	{
		return Entry->ItemClass;
	}
	return NAME_None;
}

int32 AShockSearchableContainer::GetSlotStackSize(int32 Slot) const
{
	if (const FShockContainerSlot* Entry = ScriptedSlots.Find(Slot))
	{
		return Entry->StackSize;
	}
	return 0;
}

bool AShockSearchableContainer::Search(AShockPlayer* Player)
{
	if (!Player || bSearched)
	{
		return false;
	}
	bSearched = true;

	const int32 Money = FMath::RandRange(LootMoneyMin, LootMoneyMax);
	if (Money > 0)
	{
		Player->AddMoney(Money);
	}
	if (!LootItemClass.IsNone())
	{
		Player->AddStackToInventory(LootItemClass, LootItemAmount);
	}
	TArray<int32> SlotNumbers;
	ScriptedSlots.GetKeys(SlotNumbers);
	SlotNumbers.Sort();
	for (int32 Slot : SlotNumbers)
	{
		const FShockContainerSlot* Entry = ScriptedSlots.Find(Slot);
		if (Entry && !Entry->ItemClass.IsNone() && Entry->StackSize > 0)
		{
			Player->AddStackToInventory(Entry->ItemClass, Entry->StackSize);
		}
	}

	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_CONTAINER_SEARCH label=%s money=%d item=%s scriptedSlots=%d"),
		*ScriptLabel.ToString(),
		Money,
		*LootItemClass.ToString(),
		ScriptedSlots.Num());
	return true;
}
