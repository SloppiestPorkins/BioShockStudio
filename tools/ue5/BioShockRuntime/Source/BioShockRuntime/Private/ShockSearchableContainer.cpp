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
		return;
	}
	if (UStaticMesh* Marker = LoadObject<UStaticMesh>(nullptr, TEXT("/Engine/BasicShapes/Sphere.Sphere")))
	{
		Mesh->SetStaticMesh(Marker);
	}
	Mesh->SetRelativeScale3D(FVector(0.12f));
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

	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_CONTAINER_SEARCH label=%s money=%d item=%s"),
		*ScriptLabel.ToString(),
		Money,
		*LootItemClass.ToString());
	return true;
}
