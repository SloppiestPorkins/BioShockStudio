#include "ShockStationActor.h"

#include "Components/BoxComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/World.h"
#include "EngineUtils.h"
#include "GameFramework/PlayerController.h"
#include "ShockDoor.h"
#include "ShockPlayer.h"
#include "ShockStationMenu.h"

AShockStationBase::AShockStationBase()
{
	PrimaryActorTick.bCanEverTick = false;

	Mesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Mesh"));
	SetRootComponent(Mesh);
	Mesh->SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	Mesh->SetCollisionResponseToAllChannels(ECR_Block);

	InteractTrigger = CreateDefaultSubobject<UBoxComponent>(TEXT("InteractTrigger"));
	InteractTrigger->SetupAttachment(RootComponent);
	InteractTrigger->SetBoxExtent(FVector(InteractRadius * 0.5f));
	InteractTrigger->SetCollisionEnabled(ECollisionEnabled::QueryOnly);
	InteractTrigger->SetCollisionResponseToAllChannels(ECR_Ignore);
	InteractTrigger->SetCollisionResponseToChannel(ECC_Pawn, ECR_Overlap);
}

void AShockStationBase::BeginPlay()
{
	Super::BeginPlay();
	if (InteractTrigger)
	{
		InteractTrigger->SetBoxExtent(FVector(InteractRadius * 0.5f));
	}
}

void AShockStationBase::ConfigureVendingDefaults(bool bAmmoBandito)
{
	VendItems.Reset();
	StationKind = EShockStationKind::Vending;
	if (bAmmoBandito)
	{
		StationLabel = FName(TEXT("ElAmmoBandito"));
		FShockVendItem Ballistic;
		Ballistic.ItemClass = FName(TEXT("PistolAmmo"));
		Ballistic.DisplayName = TEXT("Pistol Rounds");
		Ballistic.Price = 25;
		Ballistic.HackedPrice = 10;
		Ballistic.Stock = 4;
		Ballistic.HackedBonusStock = 2;
		Ballistic.StackPerPurchase = 12;
		VendItems.Add(Ballistic);

		FShockVendItem Auto;
		Auto.ItemClass = FName(TEXT("MachineGunAmmo"));
		Auto.DisplayName = TEXT("Machine Gun Rounds");
		Auto.Price = 40;
		Auto.HackedPrice = 18;
		Auto.Stock = 3;
		Auto.HackedBonusStock = 2;
		Auto.StackPerPurchase = 48;
		VendItems.Add(Auto);
	}
	else
	{
		StationLabel = FName(TEXT("CircusOfValues"));
		FShockVendItem Kit;
		Kit.ItemClass = FName(TEXT("FirstAidKit"));
		Kit.DisplayName = TEXT("First Aid Kit");
		Kit.Price = 20;
		Kit.HackedPrice = 8;
		Kit.Stock = 3;
		Kit.HackedBonusStock = 2;
		Kit.StackPerPurchase = 1;
		VendItems.Add(Kit);

		FShockVendItem Hypo;
		Hypo.ItemClass = FName(TEXT("EveHypo"));
		Hypo.DisplayName = TEXT("EVE Hypo");
		Hypo.Price = 20;
		Hypo.HackedPrice = 8;
		Hypo.Stock = 3;
		Hypo.HackedBonusStock = 2;
		Hypo.StackPerPurchase = 1;
		VendItems.Add(Hypo);

		FShockVendItem CashSnack;
		CashSnack.ItemClass = FName(TEXT("PepBar"));
		CashSnack.DisplayName = TEXT("Pep Bar");
		CashSnack.Price = 5;
		CashSnack.HackedPrice = 2;
		CashSnack.Stock = 5;
		CashSnack.HackedBonusStock = 3;
		CashSnack.StackPerPurchase = 1;
		VendItems.Add(CashSnack);
	}
}

void AShockStationBase::SetHacked(bool bInHacked)
{
	if (bHacked == bInHacked)
	{
		return;
	}
	bHacked = bInHacked;
	if (bHacked)
	{
		for (FShockVendItem& Item : VendItems)
		{
			Item.Stock += Item.HackedBonusStock;
		}
	}
}

AShockDoor* AShockStationBase::ResolveLinkedDoor() const
{
	if (LinkedDoorLabel.IsNone())
	{
		return nullptr;
	}
	return AShockDoor::FindByLabel(GetWorld(), LinkedDoorLabel);
}

UShockStationMenu* AShockStationBase::CreateMenuForKind(APlayerController* PC) const
{
	if (!PC)
	{
		return nullptr;
	}
	switch (StationKind)
	{
	case EShockStationKind::Vending:
		return CreateWidget<UShockVendingMenu>(PC, UShockVendingMenu::StaticClass());
	case EShockStationKind::GeneBank:
		return CreateWidget<UShockGeneBankMenu>(PC, UShockGeneBankMenu::StaticClass());
	case EShockStationKind::UInvent:
		return CreateWidget<UShockUInventMenu>(PC, UShockUInventMenu::StaticClass());
	case EShockStationKind::GathererGarden:
		return CreateWidget<UShockGathererGardenMenu>(PC, UShockGathererGardenMenu::StaticClass());
	case EShockStationKind::ComboLock:
		return CreateWidget<UShockComboLockMenu>(PC, UShockComboLockMenu::StaticClass());
	default:
		return nullptr;
	}
}

bool AShockStationBase::TryInteract(AShockPlayer* Player)
{
	if (!Player)
	{
		return false;
	}
	APlayerController* PC = Cast<APlayerController>(Player->GetController());
	if (!PC)
	{
		// Headless verify may lack a controller — still build a world-owned widget.
		PC = GetWorld() ? GetWorld()->GetFirstPlayerController() : nullptr;
	}

	if (OpenMenu && OpenMenu->IsStationOpen())
	{
		OpenMenu->CloseStationMenu();
		OpenMenu = nullptr;
		return true;
	}

	UShockStationMenu* Menu = CreateMenuForKind(PC);
	if (!Menu && GetWorld())
	{
		// Fallback: create against the world for headless.
		switch (StationKind)
		{
		case EShockStationKind::Vending:
			Menu = CreateWidget<UShockVendingMenu>(GetWorld(), UShockVendingMenu::StaticClass());
			break;
		case EShockStationKind::GeneBank:
			Menu = CreateWidget<UShockGeneBankMenu>(GetWorld(), UShockGeneBankMenu::StaticClass());
			break;
		case EShockStationKind::UInvent:
			Menu = CreateWidget<UShockUInventMenu>(GetWorld(), UShockUInventMenu::StaticClass());
			break;
		case EShockStationKind::GathererGarden:
			Menu = CreateWidget<UShockGathererGardenMenu>(
				GetWorld(), UShockGathererGardenMenu::StaticClass());
			break;
		case EShockStationKind::ComboLock:
			Menu = CreateWidget<UShockComboLockMenu>(GetWorld(), UShockComboLockMenu::StaticClass());
			break;
		default:
			break;
		}
	}
	if (!Menu)
	{
		return false;
	}

	OpenMenu = Menu;
	Menu->BindDisplayPlayer(Player);
	Menu->BindStation(this);
	if (PC && !Menu->IsInViewport())
	{
		Menu->AddToViewport(50);
	}
	Menu->OpenStationMenu();
	return true;
}

void AShockStationBase::CloseMenu()
{
	if (UShockStationMenu* Menu = OpenMenu)
	{
		OpenMenu = nullptr;
		if (Menu->IsStationOpen())
		{
			Menu->CloseStationMenu();
		}
	}
}

void AShockStationBase::NotifyMenuClosed(UShockStationMenu* Menu)
{
	if (OpenMenu == Menu)
	{
		OpenMenu = nullptr;
	}
}
