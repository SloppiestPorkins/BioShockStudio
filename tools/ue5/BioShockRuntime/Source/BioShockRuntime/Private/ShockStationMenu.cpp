#include "ShockStationMenu.h"

#include "ShockDecoStyle.h"
#include "Blueprint/WidgetTree.h"
#include "Components/Border.h"
#include "Components/Button.h"
#include "Components/HorizontalBox.h"
#include "Components/HorizontalBoxSlot.h"
#include "Components/Image.h"
#include "Components/Overlay.h"
#include "Components/OverlaySlot.h"
#include "Components/SizeBox.h"
#include "Components/TextBlock.h"
#include "Components/VerticalBox.h"
#include "Components/VerticalBoxSlot.h"
#include "Engine/Engine.h"
#include "Engine/Texture2D.h"
#include "Engine/World.h"
#include "GameFramework/PlayerController.h"
#include "InputCoreTypes.h"
#include "Kismet/GameplayStatics.h"
#include "ShockDoor.h"
#include "ShockElectroBoltPlasmid.h"
#include "ShockIncineratePlasmid.h"
#include "ShockPlayer.h"
#include "ShockStationActor.h"
#include "Styling/CoreStyle.h"

FString UShockStationMenu::LastStationsVerifyError;

namespace ShockStationMenuPrivate
{
	FSlateFontInfo StationFont(int32 Size, bool bBold = false)
	{
		return FCoreStyle::GetDefaultFontStyle(bBold ? TEXT("Bold") : TEXT("Regular"), Size);
	}

	UTextBlock* MakeLine(UUserWidget* Owner, UVerticalBox* Box, const FString& Text)
	{
		if (!Owner || !Owner->WidgetTree || !Box)
		{
			return nullptr;
		}

		UOverlay* Row =
			Owner->WidgetTree->ConstructWidget<UOverlay>(UOverlay::StaticClass(), NAME_None);
		UImage* Plate =
			Owner->WidgetTree->ConstructWidget<UImage>(UImage::StaticClass(), NAME_None);
		UShockDecoStyle::ApplyRowPlate(Plate, FVector2D(720.0f, 44.0f));
		if (UOverlaySlot* PlateSlot = Row->AddChildToOverlay(Plate))
		{
			PlateSlot->SetHorizontalAlignment(HAlign_Fill);
			PlateSlot->SetVerticalAlignment(VAlign_Fill);
		}

		UTextBlock* Line = Owner->WidgetTree->ConstructWidget<UTextBlock>(
			UTextBlock::StaticClass(), NAME_None);
		Line->SetText(FText::FromString(Text));
		Line->SetFont(StationFont(16));
		Line->SetColorAndOpacity(UShockDecoStyle::CreamColor());
		if (UOverlaySlot* TextSlot = Row->AddChildToOverlay(Line))
		{
			TextSlot->SetHorizontalAlignment(HAlign_Left);
			TextSlot->SetVerticalAlignment(VAlign_Center);
			TextSlot->SetPadding(FMargin(16.0f, 6.0f));
		}

		if (UVerticalBoxSlot* Slot = Box->AddChildToVerticalBox(Row))
		{
			Slot->SetPadding(FMargin(4.0f, 3.0f));
			Slot->SetHorizontalAlignment(HAlign_Fill);
		}
		return Line;
	}
}

UShockStationMenu::UShockStationMenu(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
	SetVisibility(ESlateVisibility::Collapsed);
	SetIsFocusable(true);
}

FString UShockStationMenu::GetLastStationsVerifyError()
{
	return LastStationsVerifyError;
}

void UShockStationMenu::BindDisplayPlayer(AShockPlayer* Player)
{
	DisplayPlayerOverride = Player;
}

void UShockStationMenu::BindStation(AShockStationBase* Station)
{
	BoundStation = Station;
}

AShockPlayer* UShockStationMenu::ResolvePlayer() const
{
	if (AShockPlayer* Override = DisplayPlayerOverride.Get())
	{
		return Override;
	}
	if (APlayerController* PC = GetOwningPlayer())
	{
		return Cast<AShockPlayer>(PC->GetPawn());
	}
	return nullptr;
}

AShockStationBase* UShockStationMenu::ResolveStation() const
{
	return BoundStation.Get();
}

void UShockStationMenu::EnsureTextures()
{
	if (!FaceTexture)
	{
		if (const TCHAR* Path = GetFaceTexturePath())
		{
			FaceTexture = LoadObject<UTexture2D>(nullptr, Path);
		}
	}
}

bool UShockStationMenu::HasRequiredTextures() const
{
	return FaceTexture != nullptr;
}

void UShockStationMenu::EnsureWidgetTree()
{
	if (!WidgetTree || RootColumn)
	{
		return;
	}

	RootColumn = WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass(), TEXT("StationRoot"));
	WidgetTree->RootWidget = RootColumn;

	PanelSize = WidgetTree->ConstructWidget<USizeBox>(USizeBox::StaticClass(), TEXT("StationPanelSize"));
	PanelSize->SetWidthOverride(UShockDecoStyle::StationPanelWidth);
	PanelSize->SetHeightOverride(UShockDecoStyle::StationPanelHeight);
	if (UVerticalBoxSlot* PanelSlot = RootColumn->AddChildToVerticalBox(PanelSize))
	{
		PanelSlot->SetHorizontalAlignment(HAlign_Center);
		PanelSlot->SetVerticalAlignment(VAlign_Center);
		PanelSlot->SetPadding(FMargin(24.0f, UShockDecoStyle::HudClearTopPadding, 24.0f, 24.0f));
	}

	PanelOverlay = WidgetTree->ConstructWidget<UOverlay>(UOverlay::StaticClass(), TEXT("StationPanelOverlay"));
	PanelSize->AddChild(PanelOverlay);

	FaceImage = WidgetTree->ConstructWidget<UImage>(UImage::StaticClass(), TEXT("StationFace"));
	FaceImage->SetDesiredSizeOverride(
		FVector2D(UShockDecoStyle::StationPanelWidth, UShockDecoStyle::StationPanelHeight));
	if (UOverlaySlot* FaceSlot = PanelOverlay->AddChildToOverlay(FaceImage))
	{
		FaceSlot->SetHorizontalAlignment(HAlign_Fill);
		FaceSlot->SetVerticalAlignment(VAlign_Fill);
	}

	UImage* PanelFill = WidgetTree->ConstructWidget<UImage>(UImage::StaticClass(), TEXT("StationPanelFill"));
	UShockDecoStyle::ApplyImageBrush(
		PanelFill,
		UShockDecoStyle::MakePanelFillBrush(
			FVector2D(UShockDecoStyle::StationPanelWidth, UShockDecoStyle::StationPanelHeight)));
	if (UOverlaySlot* FillSlot = PanelOverlay->AddChildToOverlay(PanelFill))
	{
		FillSlot->SetHorizontalAlignment(HAlign_Fill);
		FillSlot->SetVerticalAlignment(VAlign_Fill);
		FillSlot->SetPadding(FMargin(32.0f));
	}

	PanelFrame = WidgetTree->ConstructWidget<UImage>(UImage::StaticClass(), TEXT("StationPanelFrame"));
	UShockDecoStyle::ApplyPanelFrame(
		PanelFrame,
		FVector2D(UShockDecoStyle::StationPanelWidth, UShockDecoStyle::StationPanelHeight));
	if (UOverlaySlot* FrameSlot = PanelOverlay->AddChildToOverlay(PanelFrame))
	{
		FrameSlot->SetHorizontalAlignment(HAlign_Fill);
		FrameSlot->SetVerticalAlignment(VAlign_Fill);
	}

	UVerticalBox* Inner =
		WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass(), TEXT("StationInner"));
	if (UOverlaySlot* InnerSlot = PanelOverlay->AddChildToOverlay(Inner))
	{
		InnerSlot->SetHorizontalAlignment(HAlign_Fill);
		InnerSlot->SetVerticalAlignment(VAlign_Fill);
		InnerSlot->SetPadding(FMargin(36.0f, 28.0f));
	}

	TitleText = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("StationTitle"));
	TitleText->SetText(FText::FromString(GetStationTitle()));
	TitleText->SetFont(ShockStationMenuPrivate::StationFont(22, true));
	TitleText->SetColorAndOpacity(UShockDecoStyle::GoldColor());
	if (UVerticalBoxSlot* TitleSlot = Inner->AddChildToVerticalBox(TitleText))
	{
		TitleSlot->SetHorizontalAlignment(HAlign_Center);
		TitleSlot->SetPadding(FMargin(8.0f, 4.0f));
	}

	StatusText = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("StationStatus"));
	StatusText->SetFont(ShockStationMenuPrivate::StationFont(16));
	StatusText->SetColorAndOpacity(UShockDecoStyle::CreamColor());
	if (UVerticalBoxSlot* StatusSlot = Inner->AddChildToVerticalBox(StatusText))
	{
		StatusSlot->SetHorizontalAlignment(HAlign_Center);
		StatusSlot->SetPadding(FMargin(8.0f, 2.0f, 8.0f, 8.0f));
	}

	UHorizontalBox* Body =
		WidgetTree->ConstructWidget<UHorizontalBox>(UHorizontalBox::StaticClass(), TEXT("StationBody"));
	if (UVerticalBoxSlot* BodySlot = Inner->AddChildToVerticalBox(Body))
	{
		BodySlot->SetSize(FSlateChildSize(ESlateSizeRule::Fill));
		BodySlot->SetPadding(FMargin(4.0f));
	}

	SlotGridImage = WidgetTree->ConstructWidget<UImage>(UImage::StaticClass(), TEXT("StationSlotGrid"));
	UShockDecoStyle::ApplySlotGrid(SlotGridImage, FVector2D(220.0f, 280.0f));
	if (UHorizontalBoxSlot* GridSlot = Body->AddChildToHorizontalBox(SlotGridImage))
	{
		GridSlot->SetPadding(FMargin(4.0f, 4.0f, 12.0f, 4.0f));
		GridSlot->SetVerticalAlignment(VAlign_Top);
	}

	ContentBox = WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass(), TEXT("StationContent"));
	if (UHorizontalBoxSlot* ContentSlot = Body->AddChildToHorizontalBox(ContentBox))
	{
		ContentSlot->SetSize(FSlateChildSize(ESlateSizeRule::Fill));
		ContentSlot->SetPadding(FMargin(4.0f));
	}
}

TSharedRef<SWidget> UShockStationMenu::RebuildWidget()
{
	EnsureWidgetTree();
	return Super::RebuildWidget();
}

void UShockStationMenu::NativeConstruct()
{
	Super::NativeConstruct();
	EnsureWidgetTree();
}

void UShockStationMenu::SetPaused(bool bPause)
{
	UWorld* World = GetWorld();
	if (!World)
	{
		return;
	}
	UGameplayStatics::SetGamePaused(World, bPause);
	bDidPause = bPause;
	if (APlayerController* PC = GetOwningPlayer())
	{
		PC->bShowMouseCursor = bPause;
		if (bPause)
		{
			FInputModeGameAndUI Mode;
			Mode.SetWidgetToFocus(TakeWidget());
			Mode.SetLockMouseToViewportBehavior(EMouseLockMode::DoNotLock);
			PC->SetInputMode(Mode);
		}
		else
		{
			FInputModeGameOnly Mode;
			PC->SetInputMode(Mode);
		}
	}
}

void UShockStationMenu::RebuildContent()
{
	EnsureWidgetTree();
	EnsureTextures();
	if (PanelFrame)
	{
		UShockDecoStyle::ApplyPanelFrame(
			PanelFrame,
			FVector2D(UShockDecoStyle::StationPanelWidth, UShockDecoStyle::StationPanelHeight));
	}
	if (SlotGridImage)
	{
		UShockDecoStyle::ApplySlotGrid(SlotGridImage, FVector2D(220.0f, 280.0f));
	}
	if (FaceImage && FaceTexture)
	{
		// Never bMatchSize — native SWF faces are huge and push chrome off-screen.
		FaceImage->SetBrushFromTexture(FaceTexture, /*bMatchSize*/ false);
		FaceImage->SetDesiredSizeOverride(
			FVector2D(UShockDecoStyle::StationPanelWidth, UShockDecoStyle::StationPanelHeight));
		FaceImage->SetColorAndOpacity(FLinearColor(1.0f, 1.0f, 1.0f, 0.45f));
	}
	if (TitleText)
	{
		TitleText->SetText(FText::FromString(GetStationTitle()));
	}
	if (ContentBox)
	{
		ContentBox->ClearChildren();
	}
}

void UShockStationMenu::OpenStationMenu()
{
	bOpen = true;
	EnsureWidgetTree();
	EnsureTextures();
	RebuildContent();
	SetVisibility(ESlateVisibility::Visible);
	SetPaused(true);
	SetKeyboardFocus();
}

void UShockStationMenu::ForceOpenForCapture()
{
	bOpen = true;
	EnsureWidgetTree();
	EnsureTextures();
	RebuildContent();
	SetVisibility(ESlateVisibility::Visible);
}

void UShockStationMenu::CloseStationMenu()
{
	bOpen = false;
	SetVisibility(ESlateVisibility::Collapsed);
	if (bDidPause)
	{
		SetPaused(false);
	}
	if (AShockStationBase* Station = BoundStation.Get())
	{
		Station->NotifyMenuClosed(this);
	}
}

FReply UShockStationMenu::NativeOnKeyDown(const FGeometry& InGeometry, const FKeyEvent& InKeyEvent)
{
	if (!bOpen)
	{
		return Super::NativeOnKeyDown(InGeometry, InKeyEvent);
	}
	if (InKeyEvent.GetKey() == EKeys::Escape)
	{
		CloseStationMenu();
		return FReply::Handled();
	}
	return Super::NativeOnKeyDown(InGeometry, InKeyEvent);
}

// --- Vending -----------------------------------------------------------------

void UShockVendingMenu::RebuildContent()
{
	Super::RebuildContent();
	ListedItems.Reset();
	AShockStationBase* Station = ResolveStation();
	if (Station)
	{
		ListedItems = Station->GetVendItems();
	}
	AShockPlayer* Player = ResolvePlayer();
	const int32 Money = Player ? Player->GetMoney() : 0;
	const bool bHacked = Station && Station->bHacked;
	if (StatusText)
	{
		StatusText->SetText(FText::FromString(FString::Printf(
			TEXT("Money %d%s"), Money, bHacked ? TEXT("  [HACKED]") : TEXT(""))));
	}
	if (!ContentBox)
	{
		return;
	}
	for (int32 i = 0; i < ListedItems.Num(); ++i)
	{
		const FShockVendItem& Item = ListedItems[i];
		const int32 Price = bHacked ? Item.HackedPrice : Item.Price;
		ShockStationMenuPrivate::MakeLine(
			this,
			ContentBox,
			FString::Printf(
				TEXT("[%d] %s  $%d  stock=%d"),
				i,
				*Item.DisplayName,
				Price,
				Item.Stock));
	}
}

bool UShockVendingMenu::BuyItem(int32 Index)
{
	AShockPlayer* Player = ResolvePlayer();
	AShockStationBase* Station = ResolveStation();
	if (!Player || !Station || !Station->GetVendItemsMutable().IsValidIndex(Index))
	{
		return false;
	}
	FShockVendItem& Item = Station->GetVendItemsMutable()[Index];
	if (Item.Stock <= 0)
	{
		return false;
	}
	const int32 Price = Station->bHacked ? Item.HackedPrice : Item.Price;
	if (!Player->SpendMoney(Price))
	{
		return false;
	}
	Player->AddStackToInventory(Item.ItemClass, Item.StackPerPurchase);
	Item.Stock -= 1;
	RebuildContent();
	return true;
}

// --- Gene Bank ---------------------------------------------------------------

void UShockGeneBankMenu::RebuildContent()
{
	Super::RebuildContent();
	AShockPlayer* Player = ResolvePlayer();
	if (StatusText)
	{
		StatusText->SetText(FText::FromString(
			TEXT("Gap: gene tonics not implemented — plasmids only")));
	}
	if (!ContentBox || !Player)
	{
		return;
	}
	ShockStationMenuPrivate::MakeLine(this, ContentBox, TEXT("--- Owned ---"));
	const TArray<TSubclassOf<UShockPlasmid>>& Owned = Player->OwnedPlasmidClasses;
	for (int32 i = 0; i < Owned.Num(); ++i)
	{
		FString Name = Owned[i] ? Owned[i]->GetName() : TEXT("(null)");
		if (Owned[i])
		{
			if (const UShockPlasmid* CDO = Owned[i]->GetDefaultObject<UShockPlasmid>())
			{
				Name = CDO->PlasmidName.ToString();
			}
		}
		ShockStationMenuPrivate::MakeLine(
			this, ContentBox, FString::Printf(TEXT("Owned[%d] %s"), i, *Name));
	}
	ShockStationMenuPrivate::MakeLine(this, ContentBox, TEXT("--- Slots ---"));
	for (int32 PlasmidSlot = 0; PlasmidSlot < Player->EquippedPlasmids.Num(); ++PlasmidSlot)
	{
		UShockPlasmid* P = Player->EquippedPlasmids[PlasmidSlot].Get();
		const FString Name = P ? P->PlasmidName.ToString() : TEXT("(empty)");
		ShockStationMenuPrivate::MakeLine(
			this, ContentBox, FString::Printf(TEXT("Slot[%d] %s"), PlasmidSlot, *Name));
	}
}

bool UShockGeneBankMenu::EquipOwnedPlasmid(int32 OwnedIndex, int32 PlasmidSlot)
{
	AShockPlayer* Player = ResolvePlayer();
	if (!Player || !Player->OwnedPlasmidClasses.IsValidIndex(OwnedIndex))
	{
		return false;
	}
	const TSubclassOf<UShockPlasmid> Class = Player->OwnedPlasmidClasses[OwnedIndex];
	if (!Player->EquipPlasmid(Class, PlasmidSlot))
	{
		return false;
	}
	RebuildContent();
	return true;
}

bool UShockGeneBankMenu::UnequipPlasmidSlot(int32 PlasmidSlot)
{
	AShockPlayer* Player = ResolvePlayer();
	if (!Player || PlasmidSlot < 0 || PlasmidSlot >= Player->EquippedPlasmids.Num())
	{
		return false;
	}
	Player->EquippedPlasmids[PlasmidSlot] = nullptr;
	RebuildContent();
	return true;
}

// --- U-Invent ----------------------------------------------------------------

void UShockUInventMenu::BuildDefaultRecipes(TArray<FShockCraftRecipe>& OutRecipes)
{
	OutRecipes.Reset();
	{
		FShockCraftRecipe R;
		R.DisplayName = TEXT("Trap Bolt");
		R.ResultItem = FName(TEXT("TrapBolt"));
		R.ResultStack = 1;
		R.Components.Add(FName(TEXT("Glue")), 1);
		R.Components.Add(FName(TEXT("Rubber")), 1);
		R.Components.Add(FName(TEXT("Screws")), 1);
		OutRecipes.Add(R);
	}
	{
		FShockCraftRecipe R;
		R.DisplayName = TEXT("Proximity Mine");
		R.ResultItem = FName(TEXT("ProximityMine"));
		R.ResultStack = 1;
		R.Components.Add(FName(TEXT("Glue")), 2);
		R.Components.Add(FName(TEXT("Oil")), 1);
		OutRecipes.Add(R);
	}
}

void UShockUInventMenu::RebuildContent()
{
	Super::RebuildContent();
	if (Recipes.Num() == 0)
	{
		BuildDefaultRecipes(Recipes);
	}
	AShockPlayer* Player = ResolvePlayer();
	if (StatusText)
	{
		StatusText->SetText(FText::FromString(
			TEXT("Gap: no crafting-component bag — recipes use inventory stacks")));
	}
	if (!ContentBox)
	{
		return;
	}
	ShockStationMenuPrivate::MakeLine(this, ContentBox, TEXT("--- Components ---"));
	if (Player)
	{
		static const FName CompNames[] = {
			FName(TEXT("Glue")), FName(TEXT("Rubber")), FName(TEXT("Screws")), FName(TEXT("Oil"))};
		for (const FName& Comp : CompNames)
		{
			ShockStationMenuPrivate::MakeLine(
				this,
				ContentBox,
				FString::Printf(TEXT("%s x%d"), *Comp.ToString(), Player->GetInventoryStack(Comp)));
		}
	}
	ShockStationMenuPrivate::MakeLine(this, ContentBox, TEXT("--- Recipes ---"));
	for (int32 i = 0; i < Recipes.Num(); ++i)
	{
		const FShockCraftRecipe& R = Recipes[i];
		FString CompStr;
		for (const TPair<FName, int32>& Pair : R.Components)
		{
			if (!CompStr.IsEmpty())
			{
				CompStr += TEXT(", ");
			}
			CompStr += FString::Printf(TEXT("%s x%d"), *Pair.Key.ToString(), Pair.Value);
		}
		ShockStationMenuPrivate::MakeLine(
			this,
			ContentBox,
			FString::Printf(TEXT("[%d] %s <- %s"), i, *R.DisplayName, *CompStr));
	}
}

bool UShockUInventMenu::CraftRecipe(int32 RecipeIndex)
{
	AShockPlayer* Player = ResolvePlayer();
	if (Recipes.Num() == 0)
	{
		BuildDefaultRecipes(Recipes);
	}
	if (!Player || !Recipes.IsValidIndex(RecipeIndex))
	{
		return false;
	}
	const FShockCraftRecipe& R = Recipes[RecipeIndex];
	const AShockStationBase* Station = ResolveStation();
	const bool bHacked = Station && Station->bHacked;

	for (const TPair<FName, int32>& Pair : R.Components)
	{
		if (Player->GetInventoryStack(Pair.Key) < ComponentCostForHackState(Pair.Value, bHacked))
		{
			return false;
		}
	}
	for (const TPair<FName, int32>& Pair : R.Components)
	{
		Player->RemoveStackFromInventory(
			Pair.Key, ComponentCostForHackState(Pair.Value, bHacked));
	}
	Player->AddStackToInventory(R.ResultItem, R.ResultStack);
	RebuildContent();
	return true;
}

int32 UShockUInventMenu::ComponentCostForHackState(int32 FullCount, bool bHacked)
{
	if (FullCount <= 0)
	{
		return 0;
	}
	return bHacked ? FMath::CeilToInt(0.8f * static_cast<float>(FullCount)) : FullCount;
}

// --- Gatherer's Garden -------------------------------------------------------

void UShockGathererGardenMenu::RebuildContent()
{
	Super::RebuildContent();
	AShockPlayer* Player = ResolvePlayer();
	const int32 Adam = Player ? Player->GetAdam() : 0;
	const float MaxH = Player ? Player->GetMaxHealth() : 0.0f;
	const float MaxE = Player ? Player->GetMaxEve() : 0.0f;
	const int32 Slots = Player ? Player->EquippedPlasmids.Num() : 0;
	if (StatusText)
	{
		StatusText->SetText(FText::FromString(FString::Printf(
			TEXT("ADAM %d   MaxHealth %.0f   MaxEVE %.0f   Slots %d"),
			Adam,
			MaxH,
			MaxE,
			Slots)));
	}
	if (!ContentBox)
	{
		return;
	}
	ShockStationMenuPrivate::MakeLine(
		this,
		ContentBox,
		FString::Printf(TEXT("[0] +Health max (+%.0f)  cost %d"), HealthUpgradeAmount, HealthUpgradeCost));
	ShockStationMenuPrivate::MakeLine(
		this,
		ContentBox,
		FString::Printf(TEXT("[1] +EVE max (+%.0f)  cost %d"), EveUpgradeAmount, EveUpgradeCost));
	ShockStationMenuPrivate::MakeLine(
		this,
		ContentBox,
		FString::Printf(TEXT("[2] Extra plasmid slot  cost %d"), SlotUpgradeCost));
	ShockStationMenuPrivate::MakeLine(
		this,
		ContentBox,
		FString::Printf(TEXT("[3] Buy Incinerate plasmid  cost %d"), PlasmidBuyCost));
}

bool UShockGathererGardenMenu::PurchaseUpgrade(EShockGardenUpgrade Upgrade)
{
	AShockPlayer* Player = ResolvePlayer();
	if (!Player)
	{
		return false;
	}
	switch (Upgrade)
	{
	case EShockGardenUpgrade::HealthMax:
		if (!Player->SpendAdam(HealthUpgradeCost))
		{
			return false;
		}
		Player->IncreaseMaxHealth(HealthUpgradeAmount);
		break;
	case EShockGardenUpgrade::EveMax:
		if (!Player->SpendAdam(EveUpgradeCost))
		{
			return false;
		}
		Player->IncreaseMaxEve(EveUpgradeAmount);
		break;
	case EShockGardenUpgrade::PlasmidSlot:
		if (!Player->SpendAdam(SlotUpgradeCost))
		{
			return false;
		}
		Player->AddPlasmidSlot();
		break;
	case EShockGardenUpgrade::BuyPlasmid:
		if (!Player->SpendAdam(PlasmidBuyCost))
		{
			return false;
		}
		Player->GrantOwnedPlasmid(UShockIncineratePlasmid::StaticClass());
		break;
	default:
		return false;
	}
	RebuildContent();
	return true;
}

// --- Combo lock --------------------------------------------------------------

int32 UShockComboLockMenu::GetEnteredCode() const
{
	return Dials[0] * 100 + Dials[1] * 10 + Dials[2];
}

void UShockComboLockMenu::SetDial(int32 DialIndex, int32 Digit)
{
	if (DialIndex < 0 || DialIndex > 2)
	{
		return;
	}
	Dials[DialIndex] = FMath::Clamp(Digit, 0, 9);
	RebuildContent();
}

void UShockComboLockMenu::NudgeDial(int32 DialIndex, int32 Delta)
{
	if (DialIndex < 0 || DialIndex > 2)
	{
		return;
	}
	int32 Next = Dials[DialIndex] + Delta;
	while (Next < 0)
	{
		Next += 10;
	}
	Dials[DialIndex] = Next % 10;
	RebuildContent();
}

void UShockComboLockMenu::RebuildContent()
{
	Super::RebuildContent();
	AShockStationBase* Station = ResolveStation();
	const int32 Expect = Station ? Station->Code : -1;
	if (StatusText)
	{
		StatusText->SetText(FText::FromString(FString::Printf(
			TEXT("Entered %03d%s"),
			GetEnteredCode(),
			bLastSubmitCorrect ? TEXT("  OPEN") : TEXT(""))));
	}
	if (!ContentBox)
	{
		return;
	}
	ShockStationMenuPrivate::MakeLine(
		this,
		ContentBox,
		FString::Printf(
			TEXT("Dials: %d  %d  %d   (expect %03d)"),
			Dials[0],
			Dials[1],
			Dials[2],
			Expect));
}

bool UShockComboLockMenu::TrySubmitCode()
{
	AShockStationBase* Station = ResolveStation();
	bLastSubmitCorrect = false;
	if (!Station)
	{
		RebuildContent();
		return false;
	}
	const int32 Entered = GetEnteredCode();
	if (Entered != Station->Code)
	{
		RebuildContent();
		return false;
	}
	bLastSubmitCorrect = true;
	if (AShockDoor* Door = Station->ResolveLinkedDoor())
	{
		Door->SetLocked(false);
		Door->OpenDoor(true);
	}
	RebuildContent();
	return true;
}

// --- Headless verify ---------------------------------------------------------

bool UShockStationMenu::RunHeadlessStationsVerify(UObject* WorldContextObject)
{
	LastStationsVerifyError.Empty();

	UWorld* World = GEngine
		? GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::ReturnNull)
		: nullptr;
	if (!World)
	{
		LastStationsVerifyError = TEXT("no world");
		return false;
	}

	FActorSpawnParameters Params;
	Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
	AShockPlayer* Player = World->SpawnActor<AShockPlayer>(
		AShockPlayer::StaticClass(), FVector(80.0f, 40.0f, 100.0f), FRotator::ZeroRotator, Params);
	if (!Player)
	{
		LastStationsVerifyError = TEXT("spawn player failed");
		return false;
	}

	Player->AddMoney(200);
	Player->AddAdam(100);
	Player->GrantOwnedPlasmid(UShockElectroBoltPlasmid::StaticClass());
	Player->GrantOwnedPlasmid(UShockIncineratePlasmid::StaticClass());
	Player->AddStackToInventory(FName(TEXT("Glue")), 3);
	Player->AddStackToInventory(FName(TEXT("Rubber")), 2);
	Player->AddStackToInventory(FName(TEXT("Screws")), 2);
	Player->AddStackToInventory(FName(TEXT("Oil")), 1);

	auto Fail = [&](const FString& Msg) -> bool
	{
		LastStationsVerifyError = Msg;
		Player->Destroy();
		return false;
	};

	// --- Vending ---
	AShockStationBase* Vend = World->SpawnActor<AShockStationBase>(
		AShockStationBase::StaticClass(), FVector(200.0f, 0.0f, 100.0f), FRotator::ZeroRotator, Params);
	if (!Vend)
	{
		return Fail(TEXT("spawn vending failed"));
	}
	Vend->ConfigureVendingDefaults(false);
	Vend->SetHacked(true);
	UShockVendingMenu* VendMenu = CreateWidget<UShockVendingMenu>(World, UShockVendingMenu::StaticClass());
	if (!VendMenu)
	{
		Vend->Destroy();
		return Fail(TEXT("CreateWidget vending failed"));
	}
	VendMenu->BindDisplayPlayer(Player);
	VendMenu->BindStation(Vend);
	VendMenu->OpenStationMenu();
	VendMenu->EnsureTextures();
	if (!VendMenu->HasRequiredTextures())
	{
		VendMenu->CloseStationMenu();
		VendMenu->RemoveFromParent();
		Vend->Destroy();
		return Fail(TEXT("vending textures missing — run import_bioshock_ui.py Station"));
	}
	const int32 MoneyBefore = Player->GetMoney();
	const int32 KitsBefore = Player->GetInventoryStack(FName(TEXT("FirstAidKit")));
	if (!VendMenu->BuyItem(0))
	{
		VendMenu->CloseStationMenu();
		VendMenu->RemoveFromParent();
		Vend->Destroy();
		return Fail(TEXT("vending BuyItem(0) failed"));
	}
	if (Player->GetMoney() >= MoneyBefore
		|| Player->GetInventoryStack(FName(TEXT("FirstAidKit"))) <= KitsBefore)
	{
		VendMenu->CloseStationMenu();
		VendMenu->RemoveFromParent();
		Vend->Destroy();
		return Fail(TEXT("vending buy did not spend money / add stock"));
	}
	VendMenu->CloseStationMenu();
	VendMenu->RemoveFromParent();
	Vend->Destroy();

	// --- Gene Bank ---
	UShockGeneBankMenu* GeneMenu =
		CreateWidget<UShockGeneBankMenu>(World, UShockGeneBankMenu::StaticClass());
	if (!GeneMenu)
	{
		return Fail(TEXT("CreateWidget gene bank failed"));
	}
	GeneMenu->BindDisplayPlayer(Player);
	GeneMenu->OpenStationMenu();
	GeneMenu->EnsureTextures();
	if (!GeneMenu->HasRequiredTextures())
	{
		GeneMenu->CloseStationMenu();
		GeneMenu->RemoveFromParent();
		return Fail(TEXT("gene bank textures missing"));
	}
	Player->ClearAllPlasmids();
	if (!GeneMenu->EquipOwnedPlasmid(0, 0))
	{
		GeneMenu->CloseStationMenu();
		GeneMenu->RemoveFromParent();
		return Fail(TEXT("gene bank EquipOwnedPlasmid failed"));
	}
	if (!Player->EquippedPlasmids.IsValidIndex(0) || !Player->EquippedPlasmids[0].Get())
	{
		GeneMenu->CloseStationMenu();
		GeneMenu->RemoveFromParent();
		return Fail(TEXT("gene bank equip did not fill slot 0"));
	}
	GeneMenu->CloseStationMenu();
	GeneMenu->RemoveFromParent();

	// --- U-Invent ---
	UShockUInventMenu* InventMenu =
		CreateWidget<UShockUInventMenu>(World, UShockUInventMenu::StaticClass());
	if (!InventMenu)
	{
		return Fail(TEXT("CreateWidget U-Invent failed"));
	}
	InventMenu->BindDisplayPlayer(Player);
	InventMenu->OpenStationMenu();
	InventMenu->EnsureTextures();
	if (!InventMenu->HasRequiredTextures())
	{
		InventMenu->CloseStationMenu();
		InventMenu->RemoveFromParent();
		return Fail(TEXT("U-Invent textures missing"));
	}
	if (!InventMenu->CraftRecipe(0))
	{
		InventMenu->CloseStationMenu();
		InventMenu->RemoveFromParent();
		return Fail(TEXT("U-Invent CraftRecipe(0) failed"));
	}
	if (Player->GetInventoryStack(FName(TEXT("TrapBolt"))) < 1)
	{
		InventMenu->CloseStationMenu();
		InventMenu->RemoveFromParent();
		return Fail(TEXT("U-Invent craft did not grant TrapBolt"));
	}
	InventMenu->CloseStationMenu();
	InventMenu->RemoveFromParent();

	// --- Gatherer's Garden ---
	UShockGathererGardenMenu* GardenMenu =
		CreateWidget<UShockGathererGardenMenu>(World, UShockGathererGardenMenu::StaticClass());
	if (!GardenMenu)
	{
		return Fail(TEXT("CreateWidget garden failed"));
	}
	GardenMenu->BindDisplayPlayer(Player);
	GardenMenu->OpenStationMenu();
	GardenMenu->EnsureTextures();
	if (!GardenMenu->HasRequiredTextures())
	{
		GardenMenu->CloseStationMenu();
		GardenMenu->RemoveFromParent();
		return Fail(TEXT("garden textures missing"));
	}
	const float HealthBefore = Player->GetMaxHealth();
	if (!GardenMenu->PurchaseUpgrade(EShockGardenUpgrade::HealthMax))
	{
		GardenMenu->CloseStationMenu();
		GardenMenu->RemoveFromParent();
		return Fail(TEXT("garden HealthMax purchase failed"));
	}
	if (Player->GetMaxHealth() <= HealthBefore)
	{
		GardenMenu->CloseStationMenu();
		GardenMenu->RemoveFromParent();
		return Fail(TEXT("garden HealthMax did not raise MaxHealth"));
	}
	GardenMenu->CloseStationMenu();
	GardenMenu->RemoveFromParent();

	// --- Combo lock ---
	AShockDoor* Door = World->SpawnActor<AShockDoor>(
		AShockDoor::StaticClass(), FVector(300.0f, 0.0f, 100.0f), FRotator::ZeroRotator, Params);
	if (!Door)
	{
		return Fail(TEXT("spawn door failed"));
	}
	Door->ConfigureForVerify(FName(TEXT("SliceComboDoor")), true, false);

	AShockStationBase* Lock = World->SpawnActor<AShockStationBase>(
		AShockStationBase::StaticClass(), FVector(280.0f, 40.0f, 100.0f), FRotator::ZeroRotator, Params);
	if (!Lock)
	{
		Door->Destroy();
		return Fail(TEXT("spawn combo lock failed"));
	}
	Lock->StationKind = EShockStationKind::ComboLock;
	Lock->Code = 247;
	Lock->LinkedDoorLabel = FName(TEXT("SliceComboDoor"));

	UShockComboLockMenu* ComboMenu =
		CreateWidget<UShockComboLockMenu>(World, UShockComboLockMenu::StaticClass());
	if (!ComboMenu)
	{
		Lock->Destroy();
		Door->Destroy();
		return Fail(TEXT("CreateWidget combo failed"));
	}
	ComboMenu->BindDisplayPlayer(Player);
	ComboMenu->BindStation(Lock);
	ComboMenu->OpenStationMenu();
	ComboMenu->EnsureTextures();
	if (!ComboMenu->HasRequiredTextures())
	{
		ComboMenu->CloseStationMenu();
		ComboMenu->RemoveFromParent();
		Lock->Destroy();
		Door->Destroy();
		return Fail(TEXT("combo textures missing"));
	}
	ComboMenu->SetDial(0, 1);
	ComboMenu->SetDial(1, 1);
	ComboMenu->SetDial(2, 1);
	if (ComboMenu->TrySubmitCode())
	{
		ComboMenu->CloseStationMenu();
		ComboMenu->RemoveFromParent();
		Lock->Destroy();
		Door->Destroy();
		return Fail(TEXT("combo accepted wrong code 111"));
	}
	if (Door->IsOpen() || !Door->IsLocked())
	{
		ComboMenu->CloseStationMenu();
		ComboMenu->RemoveFromParent();
		Lock->Destroy();
		Door->Destroy();
		return Fail(TEXT("combo wrong code opened/unlocked door"));
	}
	ComboMenu->SetDial(0, 2);
	ComboMenu->SetDial(1, 4);
	ComboMenu->SetDial(2, 7);
	if (!ComboMenu->TrySubmitCode())
	{
		ComboMenu->CloseStationMenu();
		ComboMenu->RemoveFromParent();
		Lock->Destroy();
		Door->Destroy();
		return Fail(TEXT("combo rejected correct code 247"));
	}
	if (Door->IsLocked())
	{
		ComboMenu->CloseStationMenu();
		ComboMenu->RemoveFromParent();
		Lock->Destroy();
		Door->Destroy();
		return Fail(TEXT("combo correct code left door locked"));
	}
	ComboMenu->CloseStationMenu();
	ComboMenu->RemoveFromParent();
	Lock->Destroy();
	Door->Destroy();

	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_STATIONS_OK vend=1 gene=1 invent=1 garden=1 combo=1"));

	Player->Destroy();
	return true;
}
