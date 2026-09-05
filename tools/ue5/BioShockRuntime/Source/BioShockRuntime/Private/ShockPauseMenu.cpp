#include "ShockPauseMenu.h"

#include "ShockDecoStyle.h"
#include "ShockPlayer.h"
#include "ShockSaveLoadMenu.h"

#include "Blueprint/WidgetTree.h"
#include "Components/Button.h"
#include "Components/HorizontalBox.h"
#include "Components/HorizontalBoxSlot.h"
#include "Components/Image.h"
#include "Components/Overlay.h"
#include "Components/OverlaySlot.h"
#include "Components/SizeBox.h"
#include "Components/Spacer.h"
#include "Components/TextBlock.h"
#include "Components/VerticalBox.h"
#include "Components/VerticalBoxSlot.h"
#include "Engine/Engine.h"
#include "Engine/Texture2D.h"
#include "Engine/World.h"
#include "EngineUtils.h"
#include "GameFramework/PlayerController.h"
#include "Input/Events.h"
#include "InputCoreTypes.h"
#include "Kismet/GameplayStatics.h"
#include "Kismet/KismetSystemLibrary.h"
#include "Styling/CoreStyle.h"

FString UShockPauseMenu::LastPauseVerifyError;

namespace
{
FSlateFontInfo PauseFont(int32 Size, bool bBold = false)
{
	return FCoreStyle::GetDefaultFontStyle(bBold ? TEXT("Bold") : TEXT("Regular"), Size);
}

FLinearColor PauseGold() { return FLinearColor(0.92f, 0.78f, 0.35f, 1.0f); }
FLinearColor PauseCream() { return FLinearColor(0.92f, 0.88f, 0.75f, 1.0f); }

const TCHAR* ActionLabel(int32 Index)
{
	static const TCHAR* Labels[] = {
		TEXT("Resume"),
		TEXT("Save"),
		TEXT("Load"),
		TEXT("Options"),
		TEXT("Main Menu"),
		TEXT("Quit"),
	};
	return (Index >= 0 && Index < 6) ? Labels[Index] : TEXT("?");
}
}

void UShockPauseMenuRow::Configure(
	UShockPauseMenu* InOwner,
	int32 InRowIndex,
	const FString& Label,
	bool bSelected,
	UTexture2D* ChevronTex)
{
	OwnerMenu = InOwner;
	RowIndex = InRowIndex;
	PendingLabel = Label;
	bPendingSelected = bSelected;
	PendingChevron = ChevronTex;
	if (RowText)
	{
		RowText->SetText(FText::FromString(PendingLabel));
		RowText->SetColorAndOpacity(bPendingSelected ? PauseGold() : PauseCream());
	}
	if (Chevron)
	{
		if (UTexture2D* Tex = PendingChevron.Get())
		{
			Chevron->SetBrushFromTexture(Tex, true);
		}
		Chevron->SetVisibility(
			bPendingSelected ? ESlateVisibility::Visible : ESlateVisibility::Hidden);
	}
	if (PlateImage)
	{
		UShockDecoStyle::ApplyBanner(
			PlateImage, FVector2D(420.0f, bPendingSelected ? 52.0f : 48.0f));
		PlateImage->SetColorAndOpacity(
			bPendingSelected ? FLinearColor(1.15f, 1.1f, 0.95f, 1.0f) : FLinearColor::White);
	}
	if (RowButton)
	{
		FButtonStyle Clear = RowButton->GetStyle();
		FSlateBrush None;
		None.DrawAs = ESlateBrushDrawType::NoDrawType;
		Clear.SetNormal(None);
		Clear.SetHovered(None);
		Clear.SetPressed(None);
		RowButton->SetStyle(Clear);
	}
}

TSharedRef<SWidget> UShockPauseMenuRow::RebuildWidget()
{
	if (WidgetTree && !RowButton)
	{
		RowButton = WidgetTree->ConstructWidget<UButton>(UButton::StaticClass(), TEXT("PauseRowButton"));
		WidgetTree->RootWidget = RowButton;

		RowOverlay = WidgetTree->ConstructWidget<UOverlay>(UOverlay::StaticClass(), TEXT("PauseRowOverlay"));
		PlateImage = WidgetTree->ConstructWidget<UImage>(UImage::StaticClass(), TEXT("PauseRowPlate"));
		UShockDecoStyle::ApplyBanner(PlateImage, FVector2D(420.0f, 48.0f));
		if (UOverlaySlot* PlateSlot = RowOverlay->AddChildToOverlay(PlateImage))
		{
			PlateSlot->SetHorizontalAlignment(HAlign_Fill);
			PlateSlot->SetVerticalAlignment(VAlign_Fill);
		}

		RowBox = WidgetTree->ConstructWidget<UHorizontalBox>(UHorizontalBox::StaticClass(), TEXT("PauseRowBox"));
		Chevron = WidgetTree->ConstructWidget<UImage>(UImage::StaticClass(), TEXT("PauseChevron"));
		Chevron->SetDesiredSizeOverride(FVector2D(36.0f, 36.0f));
		if (UTexture2D* Tex = PendingChevron.Get())
		{
			Chevron->SetBrushFromTexture(Tex, true);
		}
		Chevron->SetVisibility(
			bPendingSelected ? ESlateVisibility::Visible : ESlateVisibility::Hidden);
		RowText = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("PauseRowText"));
		RowText->SetFont(PauseFont(22, true));
		RowText->SetColorAndOpacity(bPendingSelected ? PauseGold() : PauseCream());
		if (!PendingLabel.IsEmpty())
		{
			RowText->SetText(FText::FromString(PendingLabel));
		}
		if (UHorizontalBoxSlot* ChevSlot = RowBox->AddChildToHorizontalBox(Chevron))
		{
			ChevSlot->SetPadding(FMargin(16.0f, 2.0f, 12.0f, 2.0f));
			ChevSlot->SetVerticalAlignment(VAlign_Center);
		}
		if (UHorizontalBoxSlot* TextSlot = RowBox->AddChildToHorizontalBox(RowText))
		{
			TextSlot->SetVerticalAlignment(VAlign_Center);
		}
		if (UOverlaySlot* BoxSlot = RowOverlay->AddChildToOverlay(RowBox))
		{
			BoxSlot->SetHorizontalAlignment(HAlign_Left);
			BoxSlot->SetVerticalAlignment(VAlign_Center);
			BoxSlot->SetPadding(FMargin(8.0f, 4.0f));
		}

		USizeBox* RowSize =
			WidgetTree->ConstructWidget<USizeBox>(USizeBox::StaticClass(), TEXT("PauseRowSize"));
		RowSize->SetWidthOverride(420.0f);
		RowSize->SetHeightOverride(48.0f);
		RowSize->AddChild(RowOverlay);
		RowButton->AddChild(RowSize);
		FButtonStyle Clear = RowButton->GetStyle();
		FSlateBrush None;
		None.DrawAs = ESlateBrushDrawType::NoDrawType;
		Clear.SetNormal(None);
		Clear.SetHovered(None);
		Clear.SetPressed(None);
		RowButton->SetStyle(Clear);
		RowButton->OnClicked.AddDynamic(this, &UShockPauseMenuRow::HandleClicked);
	}
	return Super::RebuildWidget();
}

void UShockPauseMenuRow::HandleClicked()
{
	if (UShockPauseMenu* Owner = OwnerMenu.Get())
	{
		Owner->HandleRowClicked(RowIndex);
	}
}

UShockPauseMenu::UShockPauseMenu(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
	SetVisibility(ESlateVisibility::Collapsed);
	SetIsFocusable(true);
}

FString UShockPauseMenu::GetLastPauseVerifyError()
{
	return LastPauseVerifyError;
}

void UShockPauseMenu::BindDisplayPlayer(AShockPlayer* Player)
{
	DisplayPlayerOverride = Player;
}

AShockPlayer* UShockPauseMenu::ResolvePlayer() const
{
	if (AShockPlayer* Bound = DisplayPlayerOverride.Get())
	{
		return Bound;
	}
	if (APlayerController* PC = GetOwningPlayer())
	{
		return Cast<AShockPlayer>(PC->GetPawn());
	}
	return nullptr;
}

int32 UShockPauseMenu::CountLittleSisterActors(UObject* WorldContextObject)
{
	UWorld* World = GEngine
		? GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::ReturnNull)
		: nullptr;
	if (!World)
	{
		return 0;
	}
	int32 Count = 0;
	for (TActorIterator<AActor> It(World); It; ++It)
	{
		if (!*It || !It->GetClass())
		{
			continue;
		}
		const FString ClassName = It->GetClass()->GetName();
		if (ClassName.Contains(TEXT("LittleSister"), ESearchCase::IgnoreCase)
			|| ClassName.Contains(TEXT("Gatherer"), ESearchCase::IgnoreCase))
		{
			++Count;
		}
	}
	return Count;
}

void UShockPauseMenu::EnsureTextures()
{
	if (!LogoTexture)
	{
		LogoTexture = LoadObject<UTexture2D>(
			nullptr, TEXT("/Game/BioShockUI/Pause/T_Pause_Logo.T_Pause_Logo"));
	}
	if (!ChevronUpTexture)
	{
		ChevronUpTexture = LoadObject<UTexture2D>(
			nullptr, TEXT("/Game/BioShockUI/Pause/T_Pause_ChevronUp.T_Pause_ChevronUp"));
	}
	if (!ChevronDownTexture)
	{
		ChevronDownTexture = LoadObject<UTexture2D>(
			nullptr, TEXT("/Game/BioShockUI/Pause/T_Pause_ChevronDown.T_Pause_ChevronDown"));
	}
}

bool UShockPauseMenu::HasRequiredTextures() const
{
	return LogoTexture != nullptr && ChevronUpTexture != nullptr;
}

void UShockPauseMenu::EnsureWidgetTree()
{
	if (!WidgetTree || RootColumn)
	{
		return;
	}

	RootColumn = WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass(), TEXT("PauseRoot"));
	WidgetTree->RootWidget = RootColumn;

	// Explicit spacer — Overlay padding is unreliable under FWidgetRenderer captures.
	USpacer* TopClear =
		WidgetTree->ConstructWidget<USpacer>(USpacer::StaticClass(), TEXT("PauseHudClear"));
	TopClear->SetSize(FVector2D(1.0f, UShockDecoStyle::HudClearTopPadding));
	RootColumn->AddChildToVerticalBox(TopClear);

	BannerImage = WidgetTree->ConstructWidget<UImage>(UImage::StaticClass(), TEXT("PauseBanner"));
	if (UVerticalBoxSlot* BannerSlot = RootColumn->AddChildToVerticalBox(BannerImage))
	{
		BannerSlot->SetHorizontalAlignment(HAlign_Center);
		BannerSlot->SetPadding(FMargin(24.0f, 0.0f, 24.0f, 4.0f));
	}
	UShockDecoStyle::ApplyBanner(BannerImage, FVector2D(420.0f, 64.0f));

	// Logo omitted in pause — banner + six Deco rows must fit below HUD clear space.

	UOverlay* StatsOverlay =
		WidgetTree->ConstructWidget<UOverlay>(UOverlay::StaticClass(), TEXT("PauseStatsOverlay"));
	StatsPlate = WidgetTree->ConstructWidget<UImage>(UImage::StaticClass(), TEXT("PauseStatsPlate"));
	UShockDecoStyle::ApplyNameplate(StatsPlate, true, FVector2D(520.0f, 40.0f));
	if (UOverlaySlot* PlateSlot = StatsOverlay->AddChildToOverlay(StatsPlate))
	{
		PlateSlot->SetHorizontalAlignment(HAlign_Center);
		PlateSlot->SetVerticalAlignment(VAlign_Center);
	}
	StatsText = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("PauseStats"));
	StatsText->SetFont(PauseFont(16));
	StatsText->SetColorAndOpacity(PauseCream());
	StatsText->SetJustification(ETextJustify::Center);
	if (UOverlaySlot* TextOverlaySlot = StatsOverlay->AddChildToOverlay(StatsText))
	{
		TextOverlaySlot->SetHorizontalAlignment(HAlign_Center);
		TextOverlaySlot->SetVerticalAlignment(VAlign_Center);
		TextOverlaySlot->SetPadding(FMargin(24.0f, 6.0f));
	}
	if (UVerticalBoxSlot* StatsSlot = RootColumn->AddChildToVerticalBox(StatsOverlay))
	{
		StatsSlot->SetHorizontalAlignment(HAlign_Center);
		StatsSlot->SetPadding(FMargin(24.0f, 6.0f, 24.0f, 8.0f));
	}

	ListBox = WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass(), TEXT("PauseList"));
	if (UVerticalBoxSlot* ListSlot = RootColumn->AddChildToVerticalBox(ListBox))
	{
		ListSlot->SetHorizontalAlignment(HAlign_Center);
		ListSlot->SetPadding(FMargin(24.0f, 4.0f, 24.0f, 16.0f));
	}
}

TSharedRef<SWidget> UShockPauseMenu::RebuildWidget()
{
	EnsureWidgetTree();
	return Super::RebuildWidget();
}

void UShockPauseMenu::NativeConstruct()
{
	Super::NativeConstruct();
	EnsureWidgetTree();
}

void UShockPauseMenu::SetPaused(bool bPause)
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

void UShockPauseMenu::RefreshStats()
{
	CachedMoney = 0;
	CachedAdam = 0;
	CachedLittleSisters = CountLittleSisterActors(this);
	if (AShockPlayer* Player = ResolvePlayer())
	{
		CachedMoney = Player->GetMoney();
		CachedAdam = Player->GetAdam();
	}
	if (StatsText)
	{
		FString Note;
		if (CachedLittleSisters == 0)
		{
			Note = TEXT("  (no Little Sister / Gatherer actors on level)");
		}
		StatsText->SetText(FText::FromString(FString::Printf(
			TEXT("Money %d    ADAM %d    Little Sisters remaining %d%s"),
			CachedMoney,
			CachedAdam,
			CachedLittleSisters,
			*Note)));
	}
}

void UShockPauseMenu::RebuildList()
{
	EnsureWidgetTree();
	EnsureTextures();
	if (BannerImage)
	{
		UShockDecoStyle::ApplyBanner(BannerImage, FVector2D(420.0f, 64.0f));
	}
	if (StatsPlate)
	{
		UShockDecoStyle::ApplyNameplate(StatsPlate, true, FVector2D(520.0f, 40.0f));
	}
	if (!ListBox)
	{
		return;
	}
	ListBox->ClearChildren();
	const int32 Count = static_cast<int32>(EPauseAction::Count);
	SelectedIndex = FMath::Clamp(SelectedIndex, 0, Count - 1);
	for (int32 i = 0; i < Count; ++i)
	{
		UShockPauseMenuRow* Row = CreateWidget<UShockPauseMenuRow>(this, UShockPauseMenuRow::StaticClass());
		if (!Row)
		{
			continue;
		}
		const bool bSelected = (i == SelectedIndex);
		Row->Configure(this, i, ActionLabel(i), bSelected, ChevronUpTexture);
		if (UVerticalBoxSlot* ListRowSlot = ListBox->AddChildToVerticalBox(Row))
		{
			ListRowSlot->SetPadding(FMargin(4.0f, 6.0f));
			ListRowSlot->SetHorizontalAlignment(HAlign_Left);
		}
	}
}

void UShockPauseMenu::SetSelectedIndex(int32 Index)
{
	const int32 Count = static_cast<int32>(EPauseAction::Count);
	SelectedIndex = FMath::Clamp(Index, 0, Count - 1);
	if (bOpen)
	{
		RebuildList();
	}
}

void UShockPauseMenu::StepSelection(int32 Delta)
{
	const int32 Count = static_cast<int32>(EPauseAction::Count);
	int32 Next = SelectedIndex + Delta;
	if (Next < 0)
	{
		Next = Count - 1;
	}
	else if (Next >= Count)
	{
		Next = 0;
	}
	SetSelectedIndex(Next);
}

void UShockPauseMenu::ActivateAction(EPauseAction Action)
{
	switch (Action)
	{
	case EPauseAction::Resume:
		ClosePauseMenu();
		break;
	case EPauseAction::Save:
	case EPauseAction::Load:
	{
		const bool bSave = (Action == EPauseAction::Save);
		UShockSaveLoadMenu* SaveLoad =
			CreateWidget<UShockSaveLoadMenu>(this, UShockSaveLoadMenu::StaticClass());
		if (SaveLoad)
		{
			if (AShockPlayer* Player = ResolvePlayer())
			{
				SaveLoad->BindDisplayPlayer(Player);
			}
			SaveLoad->AddToViewport(50);
			SaveLoad->OpenSaveLoad(
				bSave ? EShockSaveLoadMode::Save : EShockSaveLoadMode::Load);
			UE_LOG(
				LogTemp,
				Display,
				TEXT("BIOSHOCK_PAUSE open=%s"),
				bSave ? TEXT("Save") : TEXT("Load"));
		}
		break;
	}
	case EPauseAction::Options:
		UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_PAUSE stub=Options (not wired)"));
		break;
	case EPauseAction::MainMenu:
		UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_PAUSE stub=MainMenu (not wired)"));
		break;
	case EPauseAction::Quit:
		if (APlayerController* PC = GetOwningPlayer())
		{
			UKismetSystemLibrary::QuitGame(this, PC, EQuitPreference::Quit, false);
		}
		else if (UWorld* World = GetWorld())
		{
			UKismetSystemLibrary::QuitGame(
				World, World->GetFirstPlayerController(), EQuitPreference::Quit, false);
		}
		break;
	default:
		break;
	}
}

void UShockPauseMenu::ActivateSelected()
{
	ActivateAction(static_cast<EPauseAction>(SelectedIndex));
}

void UShockPauseMenu::HandleRowClicked(int32 Index)
{
	SetSelectedIndex(Index);
	ActivateSelected();
}

void UShockPauseMenu::OpenPauseMenu()
{
	bOpen = true;
	SelectedIndex = 0;
	EnsureWidgetTree();
	EnsureTextures();
	RefreshStats();
	RebuildList();
	SetVisibility(ESlateVisibility::Visible);
	SetPaused(true);
	SetKeyboardFocus();
}

void UShockPauseMenu::ForceOpenForCapture()
{
	// Visible for the HUD RT draw, but do not pause — the screenshot timer must keep ticking.
	bOpen = true;
	SelectedIndex = 0;
	EnsureWidgetTree();
	EnsureTextures();
	RefreshStats();
	RebuildList();
	SetVisibility(ESlateVisibility::Visible);
}

void UShockPauseMenu::ClosePauseMenu()
{
	bOpen = false;
	SetVisibility(ESlateVisibility::Collapsed);
	if (bDidPause)
	{
		SetPaused(false);
	}
}

FReply UShockPauseMenu::NativeOnKeyDown(const FGeometry& InGeometry, const FKeyEvent& InKeyEvent)
{
	if (!bOpen)
	{
		return Super::NativeOnKeyDown(InGeometry, InKeyEvent);
	}

	const FKey Key = InKeyEvent.GetKey();
	if (Key == EKeys::Escape)
	{
		ClosePauseMenu();
		return FReply::Handled();
	}
	if (Key == EKeys::Up || Key == EKeys::Gamepad_DPad_Up)
	{
		StepSelection(-1);
		return FReply::Handled();
	}
	if (Key == EKeys::Down || Key == EKeys::Gamepad_DPad_Down)
	{
		StepSelection(1);
		return FReply::Handled();
	}
	if (Key == EKeys::Enter || Key == EKeys::Gamepad_FaceButton_Bottom)
	{
		ActivateSelected();
		return FReply::Handled();
	}
	return Super::NativeOnKeyDown(InGeometry, InKeyEvent);
}

bool UShockPauseMenu::RunHeadlessPauseVerify(UObject* WorldContextObject)
{
	LastPauseVerifyError.Empty();

	UWorld* World = GEngine
		? GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::ReturnNull)
		: nullptr;
	if (!World)
	{
		LastPauseVerifyError = TEXT("no world");
		return false;
	}

	FActorSpawnParameters Params;
	Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
	AShockPlayer* Player = World->SpawnActor<AShockPlayer>(
		AShockPlayer::StaticClass(), FVector(120.0f, 50.0f, 100.0f), FRotator::ZeroRotator, Params);
	if (!Player)
	{
		LastPauseVerifyError = TEXT("spawn player failed");
		return false;
	}

	Player->AddMoney(137);
	Player->AddAdam(42);

	UShockPauseMenu* Menu = CreateWidget<UShockPauseMenu>(World, UShockPauseMenu::StaticClass());
	if (!Menu)
	{
		LastPauseVerifyError = TEXT("CreateWidget pause failed");
		Player->Destroy();
		return false;
	}

	Menu->BindDisplayPlayer(Player);
	Menu->OpenPauseMenu();
	Menu->EnsureTextures();

	if (!Menu->HasRequiredTextures())
	{
		LastPauseVerifyError = TEXT(
			"pause textures missing — run import_bioshock_ui.py into /Game/BioShockUI/Pause");
		Menu->ClosePauseMenu();
		Menu->RemoveFromParent();
		Player->Destroy();
		return false;
	}
	if (World->IsGameWorld() && !UGameplayStatics::IsGamePaused(World))
	{
		LastPauseVerifyError = TEXT("SetGamePaused(true) did not pause on open");
		Menu->ClosePauseMenu();
		Menu->RemoveFromParent();
		Player->Destroy();
		return false;
	}
	if (Menu->GetDisplayedMoney() != 137 || Menu->GetDisplayedAdam() != 42)
	{
		LastPauseVerifyError = FString::Printf(
			TEXT("stats money=%d adam=%d want 137/42"),
			Menu->GetDisplayedMoney(),
			Menu->GetDisplayedAdam());
		Menu->ClosePauseMenu();
		Menu->RemoveFromParent();
		Player->Destroy();
		return false;
	}

	Menu->ClosePauseMenu();
	if (World->IsGameWorld() && UGameplayStatics::IsGamePaused(World))
	{
		LastPauseVerifyError = TEXT("SetGamePaused(false) did not unpause on close");
		Menu->RemoveFromParent();
		Player->Destroy();
		return false;
	}

	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_PAUSE_OK money=137 adam=42 textures=1 paused_open_close=1"));

	Menu->RemoveFromParent();
	Player->Destroy();
	return true;
}
