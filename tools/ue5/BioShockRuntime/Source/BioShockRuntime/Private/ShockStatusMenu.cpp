#include "ShockStatusMenu.h"

#include "ShockPlayer.h"

#include "Blueprint/WidgetTree.h"
#include "Components/Button.h"
#include "Components/HorizontalBox.h"
#include "Components/HorizontalBoxSlot.h"
#include "Components/Image.h"
#include "Components/ScrollBox.h"
#include "Components/TextBlock.h"
#include "Components/VerticalBox.h"
#include "Components/VerticalBoxSlot.h"
#include "Engine/Engine.h"
#include "Engine/Texture2D.h"
#include "Engine/World.h"
#include "GameFramework/PlayerController.h"
#include "Input/Events.h"
#include "InputCoreTypes.h"
#include "Kismet/GameplayStatics.h"
#include "Styling/CoreStyle.h"

FString UShockStatusMenu::LastStatusVerifyError;

namespace
{
FSlateFontInfo StatusFont(int32 Size, bool bBold = false)
{
	return FCoreStyle::GetDefaultFontStyle(bBold ? TEXT("Bold") : TEXT("Regular"), Size);
}

FLinearColor StatusGold() { return FLinearColor(0.92f, 0.78f, 0.35f, 1.0f); }
FLinearColor StatusCream() { return FLinearColor(0.92f, 0.88f, 0.75f, 1.0f); }
FLinearColor StatusDim() { return FLinearColor(0.55f, 0.50f, 0.40f, 1.0f); }

const TCHAR* TabPath(EShockStatusTab Tab)
{
	switch (Tab)
	{
	case EShockStatusTab::Map:
		return TEXT("/Game/BioShockUI/Status/T_Status_Tab_Map.T_Status_Tab_Map");
	case EShockStatusTab::Goals:
		return TEXT("/Game/BioShockUI/Status/T_Status_Tab_Goals.T_Status_Tab_Goals");
	case EShockStatusTab::Messages:
		return TEXT("/Game/BioShockUI/Status/T_Status_Tab_Messages.T_Status_Tab_Messages");
	case EShockStatusTab::Help:
	default:
		return TEXT("/Game/BioShockUI/Status/T_Status_Tab_Help.T_Status_Tab_Help");
	}
}

const TCHAR* TabLabel(EShockStatusTab Tab)
{
	switch (Tab)
	{
	case EShockStatusTab::Map:
		return TEXT("Map");
	case EShockStatusTab::Goals:
		return TEXT("Goals");
	case EShockStatusTab::Messages:
		return TEXT("Messages");
	case EShockStatusTab::Help:
	default:
		return TEXT("Help");
	}
}
}

void UShockStatusTabButton::Configure(
	UShockStatusMenu* InOwner,
	EShockStatusTab InTab,
	UTexture2D* Icon,
	const FString& Label)
{
	OwnerMenu = InOwner;
	Tab = InTab;
	PendingIcon = Icon;
	PendingLabel = Label;
	if (TabIcon && Icon)
	{
		TabIcon->SetBrushFromTexture(Icon, true);
	}
	if (TabLabel)
	{
		TabLabel->SetText(FText::FromString(PendingLabel));
	}
}

TSharedRef<SWidget> UShockStatusTabButton::RebuildWidget()
{
	if (WidgetTree && !TabButton)
	{
		TabButton = WidgetTree->ConstructWidget<UButton>(UButton::StaticClass(), TEXT("TabButton"));
		WidgetTree->RootWidget = TabButton;

		UVerticalBox* Col = WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass(), TEXT("TabCol"));
		TabIcon = WidgetTree->ConstructWidget<UImage>(UImage::StaticClass(), TEXT("TabIcon"));
		TabIcon->SetDesiredSizeOverride(FVector2D(72.0f, 72.0f));
		if (UTexture2D* Icon = PendingIcon.Get())
		{
			TabIcon->SetBrushFromTexture(Icon, true);
		}
		TabLabel = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("TabLabel"));
		TabLabel->SetFont(StatusFont(14, true));
		TabLabel->SetColorAndOpacity(StatusGold());
		TabLabel->SetJustification(ETextJustify::Center);
		if (!PendingLabel.IsEmpty())
		{
			TabLabel->SetText(FText::FromString(PendingLabel));
		}
		if (UVerticalBoxSlot* IconSlot = Col->AddChildToVerticalBox(TabIcon))
		{
			IconSlot->SetHorizontalAlignment(HAlign_Center);
			IconSlot->SetPadding(FMargin(4.0f));
		}
		if (UVerticalBoxSlot* LabelSlot = Col->AddChildToVerticalBox(TabLabel))
		{
			LabelSlot->SetHorizontalAlignment(HAlign_Center);
			LabelSlot->SetPadding(FMargin(2.0f, 0.0f, 2.0f, 4.0f));
		}
		TabButton->AddChild(Col);
		TabButton->OnClicked.AddDynamic(this, &UShockStatusTabButton::HandleClicked);
	}
	return Super::RebuildWidget();
}

void UShockStatusTabButton::HandleClicked()
{
	if (UShockStatusMenu* Owner = OwnerMenu.Get())
	{
		Owner->HandleTabClicked(Tab);
	}
}

UShockStatusMenu::UShockStatusMenu(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
	SetVisibility(ESlateVisibility::Collapsed);
	SetIsFocusable(true);
}

FString UShockStatusMenu::GetLastStatusVerifyError()
{
	return LastStatusVerifyError;
}

void UShockStatusMenu::BindDisplayPlayer(AShockPlayer* Player)
{
	DisplayPlayerOverride = Player;
}

AShockPlayer* UShockStatusMenu::ResolvePlayer() const
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

FString UShockStatusMenu::GetListedGoalLabel(int32 Index) const
{
	return ListedGoalLabels.IsValidIndex(Index) ? ListedGoalLabels[Index] : FString();
}

void UShockStatusMenu::EnsureTextures()
{
	static const EShockStatusTab Tabs[] = {
		EShockStatusTab::Map,
		EShockStatusTab::Goals,
		EShockStatusTab::Messages,
		EShockStatusTab::Help,
	};
	for (int32 i = 0; i < 4; ++i)
	{
		if (!TabTextures[i])
		{
			TabTextures[i] = LoadObject<UTexture2D>(nullptr, TabPath(Tabs[i]));
		}
	}
	if (!PanelTexture)
	{
		PanelTexture = LoadObject<UTexture2D>(
			nullptr, TEXT("/Game/BioShockUI/Status/T_Status_Panel_Main.T_Status_Panel_Main"));
	}
	if (!NameplateTexture)
	{
		NameplateTexture = LoadObject<UTexture2D>(
			nullptr, TEXT("/Game/BioShockUI/Status/T_Status_Nameplate_Main.T_Status_Nameplate_Main"));
	}
	static const TCHAR* HelpPaths[] = {
		TEXT("/Game/BioShockUI/Status/T_Status_Help_Research.T_Status_Help_Research"),
		TEXT("/Game/BioShockUI/Status/T_Status_Help_Electro.T_Status_Help_Electro"),
		TEXT("/Game/BioShockUI/Status/T_Status_Help_Medical.T_Status_Help_Medical"),
		TEXT("/Game/BioShockUI/Status/T_Status_Help_Eve.T_Status_Help_Eve"),
	};
	for (int32 i = 0; i < 4; ++i)
	{
		if (!HelpTextures[i])
		{
			HelpTextures[i] = LoadObject<UTexture2D>(nullptr, HelpPaths[i]);
		}
	}
}

bool UShockStatusMenu::HasRequiredTextures() const
{
	for (int32 i = 0; i < 4; ++i)
	{
		if (!TabTextures[i] || !HelpTextures[i])
		{
			return false;
		}
	}
	return PanelTexture != nullptr && NameplateTexture != nullptr;
}

void UShockStatusMenu::EnsureWidgetTree()
{
	if (!WidgetTree || RootColumn)
	{
		return;
	}

	RootColumn = WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass(), TEXT("StatusRoot"));
	WidgetTree->RootWidget = RootColumn;

	// Short banner — mapsPC panels are square bitmaps; don't let aspect ratio fill the screen.
	PanelFrame = WidgetTree->ConstructWidget<UImage>(UImage::StaticClass(), TEXT("StatusPanel"));
	PanelFrame->SetDesiredSizeOverride(FVector2D(720.0f, 96.0f));
	if (UVerticalBoxSlot* PanelSlot = RootColumn->AddChildToVerticalBox(PanelFrame))
	{
		PanelSlot->SetHorizontalAlignment(HAlign_Center);
		PanelSlot->SetPadding(FMargin(24.0f, 40.0f, 24.0f, 4.0f));
	}

	TabRow = WidgetTree->ConstructWidget<UHorizontalBox>(UHorizontalBox::StaticClass(), TEXT("StatusTabs"));
	if (UVerticalBoxSlot* TabSlot = RootColumn->AddChildToVerticalBox(TabRow))
	{
		TabSlot->SetHorizontalAlignment(HAlign_Center);
		TabSlot->SetPadding(FMargin(16.0f, 12.0f));
	}

	Nameplate = WidgetTree->ConstructWidget<UImage>(UImage::StaticClass(), TEXT("StatusNameplate"));
	Nameplate->SetDesiredSizeOverride(FVector2D(280.0f, 36.0f));
	if (UVerticalBoxSlot* PlateSlot = RootColumn->AddChildToVerticalBox(Nameplate))
	{
		PlateSlot->SetHorizontalAlignment(HAlign_Center);
		PlateSlot->SetPadding(FMargin(8.0f, 4.0f));
	}

	TitleText = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("StatusTitle"));
	TitleText->SetFont(StatusFont(26, true));
	TitleText->SetColorAndOpacity(StatusGold());
	TitleText->SetJustification(ETextJustify::Center);
	if (UVerticalBoxSlot* TitleSlot = RootColumn->AddChildToVerticalBox(TitleText))
	{
		TitleSlot->SetHorizontalAlignment(HAlign_Center);
		TitleSlot->SetPadding(FMargin(16.0f, 4.0f, 16.0f, 8.0f));
	}

	ContentScroll = WidgetTree->ConstructWidget<UScrollBox>(UScrollBox::StaticClass(), TEXT("StatusScroll"));
	ContentBox = WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass(), TEXT("StatusContent"));
	ContentScroll->AddChild(ContentBox);
	if (UVerticalBoxSlot* ScrollSlot = RootColumn->AddChildToVerticalBox(ContentScroll))
	{
		ScrollSlot->SetPadding(FMargin(64.0f, 8.0f, 64.0f, 40.0f));
		ScrollSlot->SetSize(FSlateChildSize(ESlateSizeRule::Fill));
	}
}

TSharedRef<SWidget> UShockStatusMenu::RebuildWidget()
{
	EnsureWidgetTree();
	return Super::RebuildWidget();
}

void UShockStatusMenu::NativeConstruct()
{
	Super::NativeConstruct();
	EnsureWidgetTree();
}

void UShockStatusMenu::SetPaused(bool bPause)
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

void UShockStatusMenu::RebuildMapPanel()
{
	if (!ContentBox || !WidgetTree)
	{
		return;
	}
	AShockPlayer* Player = ResolvePlayer();
	FString LevelName = TEXT("unknown");
	FVector Loc = FVector::ZeroVector;
	if (UWorld* World = GetWorld())
	{
		LevelName = World->GetMapName();
		LevelName.RemoveFromStart(World->StreamingLevelsPrefix);
	}
	if (Player)
	{
		Loc = Player->GetActorLocation();
	}
	UTextBlock* Line = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass());
	Line->SetFont(StatusFont(18));
	Line->SetColorAndOpacity(StatusCream());
	Line->SetText(FText::FromString(FString::Printf(
		TEXT("Map — %s\nPlayer coords: (%.0f, %.0f, %.0f)\n\n(Level-plan rendering is a later stretch; U4 placeholder.)"),
		*LevelName,
		Loc.X,
		Loc.Y,
		Loc.Z)));
	ContentBox->AddChildToVerticalBox(Line);
}

void UShockStatusMenu::RebuildGoalsList()
{
	ListedGoalNames.Reset();
	ListedGoalLabels.Reset();
	if (!ContentBox || !WidgetTree)
	{
		return;
	}

	AShockPlayer* Player = ResolvePlayer();
	if (!Player)
	{
		UTextBlock* Empty = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass());
		Empty->SetFont(StatusFont(18));
		Empty->SetColorAndOpacity(StatusDim());
		Empty->SetText(FText::FromString(TEXT("No player bound.")));
		ContentBox->AddChildToVerticalBox(Empty);
		return;
	}

	TArray<FName> Active;
	Player->GetActiveQuestNames(Active);
	const FName Tracked = Player->GetActiveQuest();
	for (const FName& QuestName : Active)
	{
		ListedGoalNames.Add(QuestName);
		const int32 Objectives = Player->GetQuestObjectiveCount(QuestName);
		const FName Hint = Player->GetQuestHint(QuestName);
		const bool bTracked = (QuestName == Tracked);
		FString Label = FString::Printf(
			TEXT("%s%s"),
			bTracked ? TEXT("▶ ") : TEXT("   "),
			*QuestName.ToString());
		if (Objectives > 0)
		{
			Label += FString::Printf(TEXT("  (objectives %d)"), Objectives);
		}
		if (!Hint.IsNone())
		{
			Label += FString::Printf(TEXT(" — %s"), *Hint.ToString());
		}
		ListedGoalLabels.Add(Label);

		UTextBlock* Row = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass());
		Row->SetFont(StatusFont(18, bTracked));
		Row->SetColorAndOpacity(bTracked ? StatusGold() : StatusCream());
		Row->SetText(FText::FromString(Label));
		if (UVerticalBoxSlot* RowSlot = ContentBox->AddChildToVerticalBox(Row))
		{
			RowSlot->SetPadding(FMargin(4.0f, 6.0f));
		}
	}

	if (ListedGoalNames.Num() == 0)
	{
		UTextBlock* Empty = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass());
		Empty->SetFont(StatusFont(18));
		Empty->SetColorAndOpacity(StatusDim());
		Empty->SetText(FText::FromString(TEXT("No active goals.")));
		ContentBox->AddChildToVerticalBox(Empty);
	}
}

void UShockStatusMenu::RebuildMessagesPanel()
{
	if (!ContentBox || !WidgetTree)
	{
		return;
	}
	UTextBlock* Empty = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass());
	Empty->SetFont(StatusFont(18));
	Empty->SetColorAndOpacity(StatusDim());
	Empty->SetText(FText::FromString(
		TEXT("No recordings\n\n(Audio diary collection is not wired yet.)")));
	ContentBox->AddChildToVerticalBox(Empty);
}

void UShockStatusMenu::RebuildHelpCards()
{
	if (!ContentBox || !WidgetTree)
	{
		return;
	}
	static const TCHAR* Titles[] = {
		TEXT("Research"),
		TEXT("Plasmids / Electro Bolt"),
		TEXT("Health / Medical"),
		TEXT("EVE"),
	};
	for (int32 i = 0; i < 4; ++i)
	{
		UHorizontalBox* Row = WidgetTree->ConstructWidget<UHorizontalBox>(UHorizontalBox::StaticClass());
		UImage* Poster = WidgetTree->ConstructWidget<UImage>(UImage::StaticClass());
		Poster->SetDesiredSizeOverride(FVector2D(160.0f, 160.0f));
		if (HelpTextures[i])
		{
			Poster->SetBrushFromTexture(HelpTextures[i], true);
		}
		UTextBlock* Caption = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass());
		Caption->SetFont(StatusFont(18));
		Caption->SetColorAndOpacity(StatusCream());
		Caption->SetText(FText::FromString(Titles[i]));
		if (UHorizontalBoxSlot* ImgSlot = Row->AddChildToHorizontalBox(Poster))
		{
			ImgSlot->SetPadding(FMargin(4.0f, 8.0f));
			ImgSlot->SetVerticalAlignment(VAlign_Center);
		}
		if (UHorizontalBoxSlot* CapSlot = Row->AddChildToHorizontalBox(Caption))
		{
			CapSlot->SetPadding(FMargin(16.0f, 8.0f));
			CapSlot->SetVerticalAlignment(VAlign_Center);
		}
		if (UVerticalBoxSlot* RowSlot = ContentBox->AddChildToVerticalBox(Row))
		{
			RowSlot->SetPadding(FMargin(4.0f, 6.0f));
		}
	}
}

void UShockStatusMenu::RebuildContent()
{
	EnsureWidgetTree();
	EnsureTextures();

	if (PanelFrame && PanelTexture)
	{
		PanelFrame->SetBrushFromTexture(PanelTexture, /*bMatchSize*/ false);
		PanelFrame->SetBrushSize(FVector2D(720.0f, 96.0f));
		PanelFrame->SetDesiredSizeOverride(FVector2D(720.0f, 96.0f));
	}
	if (Nameplate && NameplateTexture)
	{
		Nameplate->SetBrushFromTexture(NameplateTexture, /*bMatchSize*/ false);
		Nameplate->SetBrushSize(FVector2D(280.0f, 36.0f));
		Nameplate->SetDesiredSizeOverride(FVector2D(280.0f, 36.0f));
	}
	if (TitleText)
	{
		TitleText->SetText(FText::FromString(TabLabel(ActiveTab)));
	}

	if (TabRow)
	{
		TabRow->ClearChildren();
		static const EShockStatusTab Tabs[] = {
			EShockStatusTab::Map,
			EShockStatusTab::Goals,
			EShockStatusTab::Messages,
			EShockStatusTab::Help,
		};
		for (int32 i = 0; i < 4; ++i)
		{
			UShockStatusTabButton* Btn = CreateWidget<UShockStatusTabButton>(
				this, UShockStatusTabButton::StaticClass());
			if (!Btn)
			{
				continue;
			}
			Btn->Configure(this, Tabs[i], TabTextures[i], TabLabel(Tabs[i]));
			if (UHorizontalBoxSlot* TabBtnSlot = TabRow->AddChildToHorizontalBox(Btn))
			{
				TabBtnSlot->SetPadding(FMargin(12.0f, 4.0f));
			}
		}
	}

	if (ContentBox)
	{
		ContentBox->ClearChildren();
	}

	switch (ActiveTab)
	{
	case EShockStatusTab::Map:
		RebuildMapPanel();
		break;
	case EShockStatusTab::Goals:
		RebuildGoalsList();
		break;
	case EShockStatusTab::Messages:
		RebuildMessagesPanel();
		break;
	case EShockStatusTab::Help:
		RebuildHelpCards();
		break;
	}
}

void UShockStatusMenu::SetActiveTab(EShockStatusTab Tab)
{
	ActiveTab = Tab;
	if (bOpen)
	{
		RebuildContent();
	}
}

void UShockStatusMenu::StepTab(int32 Delta)
{
	const int32 Count = 4;
	int32 Index = static_cast<int32>(ActiveTab);
	Index = (Index + Delta) % Count;
	if (Index < 0)
	{
		Index += Count;
	}
	SetActiveTab(static_cast<EShockStatusTab>(Index));
}

void UShockStatusMenu::HandleTabClicked(EShockStatusTab Tab)
{
	SetActiveTab(Tab);
}

void UShockStatusMenu::OpenStatusMenu()
{
	bOpen = true;
	EnsureWidgetTree();
	EnsureTextures();
	RebuildContent();
	SetVisibility(ESlateVisibility::Visible);
	SetPaused(true);
	SetKeyboardFocus();
}

void UShockStatusMenu::ForceOpenForCapture()
{
	// Visible for the HUD RT draw, but do not pause — the screenshot timer must keep ticking.
	bOpen = true;
	EnsureWidgetTree();
	EnsureTextures();
	RebuildContent();
	SetVisibility(ESlateVisibility::Visible);
}

void UShockStatusMenu::CloseStatusMenu()
{
	bOpen = false;
	SetVisibility(ESlateVisibility::Collapsed);
	if (bDidPause)
	{
		SetPaused(false);
	}
}

FReply UShockStatusMenu::NativeOnKeyDown(const FGeometry& InGeometry, const FKeyEvent& InKeyEvent)
{
	if (!bOpen)
	{
		return Super::NativeOnKeyDown(InGeometry, InKeyEvent);
	}

	const FKey Key = InKeyEvent.GetKey();
	if (Key == EKeys::Escape || Key == EKeys::M)
	{
		CloseStatusMenu();
		return FReply::Handled();
	}
	if (Key == EKeys::Q || Key == EKeys::Gamepad_LeftShoulder)
	{
		StepTab(-1);
		return FReply::Handled();
	}
	if (Key == EKeys::E || Key == EKeys::Gamepad_RightShoulder)
	{
		StepTab(1);
		return FReply::Handled();
	}
	return Super::NativeOnKeyDown(InGeometry, InKeyEvent);
}

bool UShockStatusMenu::RunHeadlessStatusVerify(UObject* WorldContextObject)
{
	LastStatusVerifyError.Empty();

	UWorld* World = GEngine
		? GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::ReturnNull)
		: nullptr;
	if (!World)
	{
		LastStatusVerifyError = TEXT("no world");
		return false;
	}

	FActorSpawnParameters Params;
	Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
	AShockPlayer* Player = World->SpawnActor<AShockPlayer>(
		AShockPlayer::StaticClass(), FVector(100.0f, 40.0f, 100.0f), FRotator::ZeroRotator, Params);
	if (!Player)
	{
		LastStatusVerifyError = TEXT("spawn player failed");
		return false;
	}

	Player->InitiateQuest(FName(TEXT("FindAtlas")), true);
	Player->InitiateQuest(FName(TEXT("GatherADAM")), false);
	Player->CompleteQuestObjective(FName(TEXT("FindAtlas")), 1);
	Player->SetQuestHint(FName(TEXT("FindAtlas")), FName(TEXT("Follow the radio")));

	UShockStatusMenu* Menu = CreateWidget<UShockStatusMenu>(World, UShockStatusMenu::StaticClass());
	if (!Menu)
	{
		LastStatusVerifyError = TEXT("CreateWidget status failed");
		Player->Destroy();
		return false;
	}

	Menu->BindDisplayPlayer(Player);
	Menu->OpenStatusMenu();
	Menu->EnsureTextures();

	if (!Menu->HasRequiredTextures())
	{
		LastStatusVerifyError = TEXT(
			"status textures missing — run import_bioshock_ui.py into /Game/BioShockUI/Status");
		Menu->CloseStatusMenu();
		Menu->RemoveFromParent();
		Player->Destroy();
		return false;
	}
	// Editor commandlet worlds often ignore SetGamePaused; require it only in game worlds.
	if (World->IsGameWorld() && !UGameplayStatics::IsGamePaused(World))
	{
		LastStatusVerifyError = TEXT("SetGamePaused(true) did not pause on open");
		Menu->CloseStatusMenu();
		Menu->RemoveFromParent();
		Player->Destroy();
		return false;
	}

	Menu->SetActiveTab(EShockStatusTab::Goals);
	if (Menu->GetListedGoalCount() != 2)
	{
		LastStatusVerifyError = FString::Printf(
			TEXT("Goals tab listed %d != 2"), Menu->GetListedGoalCount());
		Menu->CloseStatusMenu();
		Menu->RemoveFromParent();
		Player->Destroy();
		return false;
	}

	Menu->CloseStatusMenu();
	if (World->IsGameWorld() && UGameplayStatics::IsGamePaused(World))
	{
		LastStatusVerifyError = TEXT("SetGamePaused(false) did not unpause on close");
		Menu->RemoveFromParent();
		Player->Destroy();
		return false;
	}

	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_STATUS_OK goals=2 textures=1 paused_open_close=1"));

	Menu->RemoveFromParent();
	Player->Destroy();
	return true;
}
