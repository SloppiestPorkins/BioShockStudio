#include "ShockMainMenuWidget.h"

#include "ShockDifficultySelect.h"
#include "ShockGameInstance.h"
#include "ShockLoadingScreen.h"
#include "ShockSaveGame.h"
#include "ShockSaveLoadMenu.h"
#include "ShockStubMenu.h"

#include "Blueprint/WidgetTree.h"
#include "Components/Border.h"
#include "Components/Button.h"
#include "Components/HorizontalBox.h"
#include "Components/HorizontalBoxSlot.h"
#include "Components/Image.h"
#include "Components/TextBlock.h"
#include "Components/VerticalBox.h"
#include "Components/VerticalBoxSlot.h"
#include "Engine/Engine.h"
#include "Engine/Texture2D.h"
#include "Engine/World.h"
#include "Input/Events.h"
#include "InputCoreTypes.h"
#include "Kismet/GameplayStatics.h"
#include "Kismet/KismetSystemLibrary.h"
#include "Styling/CoreStyle.h"

FString UShockMainMenuWidget::LastMainMenuVerifyError;
FString UShockMainMenuWidget::LastFrontendVerifyError;

namespace
{
constexpr const TCHAR* DefaultPlayLevel = TEXT("/Game/BioShockSlice/1-Medical");
constexpr const TCHAR* DefaultTravelOptions = TEXT("game=/Script/BioShockRuntime.ShockGameMode");

FSlateFontInfo MenuFont(int32 Size, bool bBold = false)
{
	return FCoreStyle::GetDefaultFontStyle(bBold ? TEXT("Bold") : TEXT("Regular"), Size);
}

FLinearColor MenuGold() { return FLinearColor(0.92f, 0.78f, 0.35f, 1.0f); }
FLinearColor MenuCream() { return FLinearColor(0.92f, 0.88f, 0.75f, 1.0f); }
}

const TCHAR* UShockMainMenuWidget::ActionLabel(int32 Index)
{
	static const TCHAR* Labels[] = {
		TEXT("New Game"),
		TEXT("Continue"),
		TEXT("Load Game"),
		TEXT("Options"),
		TEXT("Credits"),
		TEXT("Director's Commentary"),
		TEXT("Museum"),
		TEXT("Challenge Rooms"),
		TEXT("Exit"),
	};
	return (Index >= 0 && Index < static_cast<int32>(EMainMenuAction::Count)) ? Labels[Index]
																			  : TEXT("?");
}

void UShockMainMenuRow::Configure(
	UShockMainMenuWidget* InOwner,
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
		RowText->SetColorAndOpacity(bPendingSelected ? MenuGold() : MenuCream());
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
}

TSharedRef<SWidget> UShockMainMenuRow::RebuildWidget()
{
	if (WidgetTree && !RowButton)
	{
		RowButton = WidgetTree->ConstructWidget<UButton>(UButton::StaticClass(), TEXT("MainRowButton"));
		WidgetTree->RootWidget = RowButton;
		RowBox = WidgetTree->ConstructWidget<UHorizontalBox>(UHorizontalBox::StaticClass(), TEXT("MainRowBox"));
		Chevron = WidgetTree->ConstructWidget<UImage>(UImage::StaticClass(), TEXT("MainChevron"));
		Chevron->SetDesiredSizeOverride(FVector2D(36.0f, 36.0f));
		if (UTexture2D* Tex = PendingChevron.Get())
		{
			Chevron->SetBrushFromTexture(Tex, true);
		}
		Chevron->SetVisibility(
			bPendingSelected ? ESlateVisibility::Visible : ESlateVisibility::Hidden);
		RowText = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("MainRowText"));
		RowText->SetFont(MenuFont(24, true));
		RowText->SetColorAndOpacity(bPendingSelected ? MenuGold() : MenuCream());
		if (!PendingLabel.IsEmpty())
		{
			RowText->SetText(FText::FromString(PendingLabel));
		}
		if (UHorizontalBoxSlot* ChevSlot = RowBox->AddChildToHorizontalBox(Chevron))
		{
			ChevSlot->SetPadding(FMargin(4.0f, 2.0f, 12.0f, 2.0f));
			ChevSlot->SetVerticalAlignment(VAlign_Center);
		}
		if (UHorizontalBoxSlot* TextSlot = RowBox->AddChildToHorizontalBox(RowText))
		{
			TextSlot->SetVerticalAlignment(VAlign_Center);
		}
		RowButton->AddChild(RowBox);
		RowButton->OnClicked.AddDynamic(this, &UShockMainMenuRow::HandleClicked);
	}
	return Super::RebuildWidget();
}

void UShockMainMenuRow::HandleClicked()
{
	if (UShockMainMenuWidget* Owner = OwnerMenu.Get())
	{
		Owner->HandleRowClicked(RowIndex);
	}
}

UShockMainMenuWidget::UShockMainMenuWidget(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
	PlayLevelPath = DefaultPlayLevel;
	PlayTravelOptions = DefaultTravelOptions;
	SetIsFocusable(true);
}

FString UShockMainMenuWidget::GetLastMainMenuVerifyError()
{
	return LastMainMenuVerifyError;
}

FString UShockMainMenuWidget::GetLastFrontendVerifyError()
{
	return LastFrontendVerifyError;
}

FString UShockMainMenuWidget::GetResolvedPlayLevelPath() const
{
	if (!PlayLevelPath.IsEmpty())
	{
		return PlayLevelPath;
	}
	return DefaultPlayLevel;
}

int32 UShockMainMenuWidget::GetMenuEntryCount() const
{
	return static_cast<int32>(EMainMenuAction::Count);
}

void UShockMainMenuWidget::EnsureTextures()
{
	if (!LogoTexture)
	{
		LogoTexture = LoadObject<UTexture2D>(
			nullptr, TEXT("/Game/BioShockUI/Pause/T_Pause_Logo.T_Pause_Logo"));
	}
	if (!ChevronTexture)
	{
		ChevronTexture = LoadObject<UTexture2D>(
			nullptr, TEXT("/Game/BioShockUI/Pause/T_Pause_ChevronUp.T_Pause_ChevronUp"));
	}
}

void UShockMainMenuWidget::EnsureWidgetTree()
{
	if (!WidgetTree || RootBorder)
	{
		return;
	}

	// Dark Deco gradient stand-in — no still menu plate found in sharedlibrary /
	// BinkMovies (attractMovie / Bathy_BG are motion loops, not UMG plates).
	RootBorder = WidgetTree->ConstructWidget<UBorder>(UBorder::StaticClass(), TEXT("MenuRootBorder"));
	WidgetTree->RootWidget = RootBorder;
	RootBorder->SetBrushColor(FLinearColor(0.02f, 0.06f, 0.09f, 1.0f));
	RootBorder->SetPadding(FMargin(48.0f, 40.0f));

	RootBox = WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass(), TEXT("MenuRoot"));
	RootBorder->AddChild(RootBox);

	LogoImage = WidgetTree->ConstructWidget<UImage>(UImage::StaticClass(), TEXT("MenuLogo"));
	LogoImage->SetDesiredSizeOverride(FVector2D(512.0f, 256.0f));
	if (UVerticalBoxSlot* LogoSlot = RootBox->AddChildToVerticalBox(LogoImage))
	{
		LogoSlot->SetHorizontalAlignment(HAlign_Center);
		LogoSlot->SetPadding(FMargin(0.0f, 24.0f, 0.0f, 16.0f));
	}

	TitleFallback = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("Title"));
	TitleFallback->SetText(FText::FromString(TEXT("BIOSHOCK")));
	TitleFallback->SetFont(MenuFont(56, true));
	TitleFallback->SetColorAndOpacity(MenuGold());
	TitleFallback->SetVisibility(ESlateVisibility::Collapsed);
	if (UVerticalBoxSlot* TitleSlot = RootBox->AddChildToVerticalBox(TitleFallback))
	{
		TitleSlot->SetHorizontalAlignment(HAlign_Center);
		TitleSlot->SetPadding(FMargin(0.0f, 8.0f, 0.0f, 24.0f));
	}

	ListBox = WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass(), TEXT("MenuList"));
	if (UVerticalBoxSlot* ListSlot = RootBox->AddChildToVerticalBox(ListBox))
	{
		ListSlot->SetHorizontalAlignment(HAlign_Center);
		ListSlot->SetPadding(FMargin(0.0f, 8.0f));
	}

	// Legacy button pointers for old WBP bindings — hidden, unused.
	PlayButton = WidgetTree->ConstructWidget<UButton>(UButton::StaticClass(), TEXT("PlayButton"));
	OptionsButton = WidgetTree->ConstructWidget<UButton>(UButton::StaticClass(), TEXT("OptionsButton"));
	QuitButton = WidgetTree->ConstructWidget<UButton>(UButton::StaticClass(), TEXT("QuitButton"));
	PlayButton->SetVisibility(ESlateVisibility::Collapsed);
	OptionsButton->SetVisibility(ESlateVisibility::Collapsed);
	QuitButton->SetVisibility(ESlateVisibility::Collapsed);
}

void UShockMainMenuWidget::RebuildList()
{
	EnsureWidgetTree();
	EnsureTextures();

	if (LogoImage)
	{
		if (LogoTexture)
		{
			LogoImage->SetBrushFromTexture(LogoTexture, true);
			LogoImage->SetVisibility(ESlateVisibility::Visible);
			if (TitleFallback)
			{
				TitleFallback->SetVisibility(ESlateVisibility::Collapsed);
			}
		}
		else if (TitleFallback)
		{
			LogoImage->SetVisibility(ESlateVisibility::Collapsed);
			TitleFallback->SetVisibility(ESlateVisibility::Visible);
		}
	}

	if (!ListBox)
	{
		return;
	}
	ListBox->ClearChildren();
	const int32 Count = static_cast<int32>(EMainMenuAction::Count);
	SelectedIndex = FMath::Clamp(SelectedIndex, 0, Count - 1);
	for (int32 i = 0; i < Count; ++i)
	{
		UShockMainMenuRow* Row = CreateWidget<UShockMainMenuRow>(this, UShockMainMenuRow::StaticClass());
		if (!Row)
		{
			continue;
		}
		Row->Configure(this, i, ActionLabel(i), i == SelectedIndex, ChevronTexture);
		if (UVerticalBoxSlot* BoxSlot = ListBox->AddChildToVerticalBox(Row))
		{
			BoxSlot->SetPadding(FMargin(4.0f, 6.0f));
			BoxSlot->SetHorizontalAlignment(HAlign_Left);
		}
	}
}

TSharedRef<SWidget> UShockMainMenuWidget::RebuildWidget()
{
	EnsureWidgetTree();
	RebuildList();
	return Super::RebuildWidget();
}

void UShockMainMenuWidget::NativeConstruct()
{
	EnsureWidgetTree();
	Super::NativeConstruct();
	RebuildList();
	SetKeyboardFocus();
}

void UShockMainMenuWidget::SetSelectedIndex(int32 Index)
{
	const int32 Count = static_cast<int32>(EMainMenuAction::Count);
	SelectedIndex = FMath::Clamp(Index, 0, Count - 1);
	RebuildList();
}

void UShockMainMenuWidget::OpenDifficulty()
{
	if (!DifficultySelect)
	{
		DifficultySelect = CreateWidget<UShockDifficultySelect>(this, UShockDifficultySelect::StaticClass());
		if (DifficultySelect)
		{
			DifficultySelect->FirstLevelPath = GetResolvedPlayLevelPath();
			DifficultySelect->TravelOptions = PlayTravelOptions;
			DifficultySelect->AddToViewport(10);
		}
	}
	if (DifficultySelect)
	{
		DifficultySelect->FirstLevelPath = GetResolvedPlayLevelPath();
		DifficultySelect->TravelOptions = PlayTravelOptions;
		DifficultySelect->OpenDifficultySelect();
	}
}

void UShockMainMenuWidget::OpenSaveLoad(bool bSaveMode)
{
	if (!SaveLoadMenu)
	{
		SaveLoadMenu = CreateWidget<UShockSaveLoadMenu>(this, UShockSaveLoadMenu::StaticClass());
		if (SaveLoadMenu)
		{
			SaveLoadMenu->AddToViewport(10);
		}
	}
	if (SaveLoadMenu)
	{
		SaveLoadMenu->OpenSaveLoad(
			bSaveMode ? EShockSaveLoadMode::Save : EShockSaveLoadMode::Load);
	}
}

void UShockMainMenuWidget::OpenStub(const FString& Title)
{
	if (!StubMenu)
	{
		StubMenu = CreateWidget<UShockStubMenu>(this, UShockStubMenu::StaticClass());
		if (StubMenu)
		{
			StubMenu->AddToViewport(10);
		}
	}
	if (StubMenu)
	{
		StubMenu->OpenStub(Title);
	}
}

void UShockMainMenuWidget::TryContinue()
{
	int32 BestSlot = INDEX_NONE;
	int64 BestTicks = 0;
	for (int32 i = 0; i < UShockSaveGame::MaxSlots; ++i)
	{
		const FString SlotName = UShockSaveGame::MakeSlotName(i);
		if (!UGameplayStatics::DoesSaveGameExist(SlotName, 0))
		{
			continue;
		}
		if (UShockSaveGame* Loaded =
				Cast<UShockSaveGame>(UGameplayStatics::LoadGameFromSlot(SlotName, 0)))
		{
			if (Loaded->SavedUtcTicks >= BestTicks)
			{
				BestTicks = Loaded->SavedUtcTicks;
				BestSlot = i;
			}
		}
	}
	if (BestSlot == INDEX_NONE)
	{
		UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_CONTINUE no saves"));
		return;
	}

	OpenSaveLoad(false);
	if (SaveLoadMenu)
	{
		SaveLoadMenu->SetSelectedSlot(BestSlot);
		SaveLoadMenu->ActivateSelectedSlot();
	}
}

void UShockMainMenuWidget::ActivateSelected()
{
	switch (static_cast<EMainMenuAction>(SelectedIndex))
	{
	case EMainMenuAction::NewGame:
		OpenDifficulty();
		break;
	case EMainMenuAction::Continue:
		TryContinue();
		break;
	case EMainMenuAction::LoadGame:
		OpenSaveLoad(false);
		break;
	case EMainMenuAction::Options:
		OpenStub(TEXT("Options"));
		break;
	case EMainMenuAction::Credits:
		// CreditsContainer.swf text extract deferred — stub panel.
		OpenStub(TEXT("Credits"));
		break;
	case EMainMenuAction::DirectorsCommentary:
		OpenStub(TEXT("Director's Commentary"));
		break;
	case EMainMenuAction::Museum:
		OpenStub(TEXT("Museum"));
		break;
	case EMainMenuAction::ChallengeRooms:
		OpenStub(TEXT("Challenge Rooms"));
		break;
	case EMainMenuAction::Exit:
		OnQuitClicked();
		break;
	default:
		break;
	}
}

void UShockMainMenuWidget::HandleRowClicked(int32 Index)
{
	SetSelectedIndex(Index);
	ActivateSelected();
}

void UShockMainMenuWidget::OnPlayClicked()
{
	SelectedIndex = static_cast<int32>(EMainMenuAction::NewGame);
	OpenDifficulty();
}

void UShockMainMenuWidget::OnOptionsClicked()
{
	OpenStub(TEXT("Options"));
}

void UShockMainMenuWidget::OnQuitClicked()
{
	UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_MENU_QUIT"));
	UKismetSystemLibrary::QuitGame(
		this, GetOwningPlayer(), EQuitPreference::Quit, /*bIgnorePlatformRestrictions=*/false);
}

FReply UShockMainMenuWidget::NativeOnKeyDown(const FGeometry& InGeometry, const FKeyEvent& InKeyEvent)
{
	const FKey Key = InKeyEvent.GetKey();
	const int32 Count = static_cast<int32>(EMainMenuAction::Count);
	if (Key == EKeys::Up || Key == EKeys::Gamepad_DPad_Up)
	{
		SetSelectedIndex(SelectedIndex <= 0 ? Count - 1 : SelectedIndex - 1);
		return FReply::Handled();
	}
	if (Key == EKeys::Down || Key == EKeys::Gamepad_DPad_Down)
	{
		SetSelectedIndex(SelectedIndex >= Count - 1 ? 0 : SelectedIndex + 1);
		return FReply::Handled();
	}
	if (Key == EKeys::Enter || Key == EKeys::Gamepad_FaceButton_Bottom)
	{
		ActivateSelected();
		return FReply::Handled();
	}
	return Super::NativeOnKeyDown(InGeometry, InKeyEvent);
}

bool UShockMainMenuWidget::RunHeadlessMainMenuVerify(UObject* WorldContextObject)
{
	LastMainMenuVerifyError.Empty();
	UWorld* World = GEngine
		? GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::ReturnNull)
		: nullptr;
	if (!World)
	{
		LastMainMenuVerifyError = TEXT("no world");
		return false;
	}

	UShockMainMenuWidget* Menu =
		CreateWidget<UShockMainMenuWidget>(World, UShockMainMenuWidget::StaticClass());
	if (!Menu)
	{
		LastMainMenuVerifyError = TEXT("CreateWidget main menu failed");
		return false;
	}

	Menu->RebuildWidget();
	if (Menu->GetMenuEntryCount() != 9)
	{
		LastMainMenuVerifyError = FString::Printf(
			TEXT("expected 9 menu entries, got %d"), Menu->GetMenuEntryCount());
		return false;
	}
	if (!Menu->GetResolvedPlayLevelPath().Contains(TEXT("1-Medical")))
	{
		LastMainMenuVerifyError = TEXT("PlayLevelPath not Medical slice");
		return false;
	}
	return true;
}

bool UShockMainMenuWidget::RunHeadlessFrontendVerify(UObject* WorldContextObject)
{
	LastFrontendVerifyError.Empty();

	if (!RunHeadlessMainMenuVerify(WorldContextObject))
	{
		LastFrontendVerifyError = FString::Printf(
			TEXT("main menu: %s"), *LastMainMenuVerifyError);
		return false;
	}
	if (!UShockDifficultySelect::RunHeadlessDifficultyVerify(WorldContextObject))
	{
		LastFrontendVerifyError = FString::Printf(
			TEXT("difficulty: %s"), *UShockDifficultySelect::GetLastDifficultyVerifyError());
		return false;
	}
	if (!UShockSaveLoadMenu::RunHeadlessSaveLoadVerify(WorldContextObject))
	{
		LastFrontendVerifyError = FString::Printf(
			TEXT("save/load: %s"), *UShockSaveLoadMenu::GetLastSaveLoadVerifyError());
		return false;
	}
	if (!UShockLoadingScreen::RunHeadlessLoadingScreenVerify(WorldContextObject))
	{
		LastFrontendVerifyError = FString::Printf(
			TEXT("loading: %s"), *UShockLoadingScreen::GetLastLoadingScreenVerifyError());
		return false;
	}
	return true;
}
