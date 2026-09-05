#include "ShockDifficultySelect.h"

#include "ShockGameInstance.h"

#include "Blueprint/WidgetTree.h"
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
#include "Styling/CoreStyle.h"

FString UShockDifficultySelect::LastVerifyError;

namespace
{
FSlateFontInfo DiffFont(int32 Size, bool bBold = false)
{
	return FCoreStyle::GetDefaultFontStyle(bBold ? TEXT("Bold") : TEXT("Regular"), Size);
}

FLinearColor DiffGold() { return FLinearColor(0.92f, 0.78f, 0.35f, 1.0f); }
FLinearColor DiffCream() { return FLinearColor(0.92f, 0.88f, 0.75f, 1.0f); }

EShockDifficulty IndexToDiff(int32 Index)
{
	switch (Index)
	{
	case 0:
		return EShockDifficulty::Easy;
	case 1:
		return EShockDifficulty::Medium;
	case 2:
		return EShockDifficulty::Hard;
	default:
		return EShockDifficulty::Survivor;
	}
}
}

void UShockDifficultySelectRow::Configure(
	UShockDifficultySelect* InOwner,
	int32 InRowIndex,
	EShockDifficulty Diff,
	bool bSelected,
	UTexture2D* ChevronTex)
{
	OwnerMenu = InOwner;
	RowIndex = InRowIndex;
	PendingDiff = Diff;
	bPendingSelected = bSelected;
	PendingChevron = ChevronTex;

	if (NameText)
	{
		NameText->SetText(FText::FromString(ShockDifficultyText::DisplayName(Diff)));
		NameText->SetColorAndOpacity(bSelected ? DiffGold() : DiffCream());
	}
	if (DescText)
	{
		DescText->SetText(FText::FromString(ShockDifficultyText::Description(Diff)));
		DescText->SetColorAndOpacity(bSelected ? DiffGold() : FLinearColor(0.65f, 0.7f, 0.75f, 1.0f));
	}
	if (Chevron)
	{
		if (UTexture2D* Tex = PendingChevron.Get())
		{
			Chevron->SetBrushFromTexture(Tex, true);
		}
		Chevron->SetVisibility(bSelected ? ESlateVisibility::Visible : ESlateVisibility::Hidden);
	}
}

TSharedRef<SWidget> UShockDifficultySelectRow::RebuildWidget()
{
	if (WidgetTree && !RowButton)
	{
		RowButton = WidgetTree->ConstructWidget<UButton>(UButton::StaticClass(), TEXT("DiffRowButton"));
		WidgetTree->RootWidget = RowButton;

		RowBox = WidgetTree->ConstructWidget<UHorizontalBox>(UHorizontalBox::StaticClass(), TEXT("DiffRowBox"));
		Chevron = WidgetTree->ConstructWidget<UImage>(UImage::StaticClass(), TEXT("DiffChevron"));
		Chevron->SetDesiredSizeOverride(FVector2D(32.0f, 32.0f));
		if (UTexture2D* Tex = PendingChevron.Get())
		{
			Chevron->SetBrushFromTexture(Tex, true);
		}
		Chevron->SetVisibility(
			bPendingSelected ? ESlateVisibility::Visible : ESlateVisibility::Hidden);

		UVerticalBox* Labels =
			WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass(), TEXT("DiffLabels"));
		NameText = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("DiffName"));
		NameText->SetFont(DiffFont(24, true));
		NameText->SetColorAndOpacity(bPendingSelected ? DiffGold() : DiffCream());
		NameText->SetText(FText::FromString(ShockDifficultyText::DisplayName(PendingDiff)));
		DescText = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("DiffDesc"));
		DescText->SetFont(DiffFont(16, false));
		DescText->SetColorAndOpacity(FLinearColor(0.65f, 0.7f, 0.75f, 1.0f));
		DescText->SetText(FText::FromString(ShockDifficultyText::Description(PendingDiff)));
		Labels->AddChildToVerticalBox(NameText);
		Labels->AddChildToVerticalBox(DescText);

		if (UHorizontalBoxSlot* ChevSlot = RowBox->AddChildToHorizontalBox(Chevron))
		{
			ChevSlot->SetPadding(FMargin(4.0f, 2.0f, 12.0f, 2.0f));
			ChevSlot->SetVerticalAlignment(VAlign_Center);
		}
		if (UHorizontalBoxSlot* TextSlot = RowBox->AddChildToHorizontalBox(Labels))
		{
			TextSlot->SetVerticalAlignment(VAlign_Center);
		}
		RowButton->AddChild(RowBox);
		RowButton->OnClicked.AddDynamic(this, &UShockDifficultySelectRow::HandleClicked);
	}
	return Super::RebuildWidget();
}

void UShockDifficultySelectRow::HandleClicked()
{
	if (UShockDifficultySelect* Owner = OwnerMenu.Get())
	{
		Owner->HandleRowClicked(RowIndex);
	}
}

UShockDifficultySelect::UShockDifficultySelect(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
	SetVisibility(ESlateVisibility::Collapsed);
	SetIsFocusable(true);
}

FString UShockDifficultySelect::GetLastDifficultyVerifyError()
{
	return LastVerifyError;
}

void UShockDifficultySelect::EnsureTextures()
{
	if (!ChevronTexture)
	{
		ChevronTexture = LoadObject<UTexture2D>(
			nullptr, TEXT("/Game/BioShockUI/Pause/T_Pause_ChevronUp.T_Pause_ChevronUp"));
	}
}

void UShockDifficultySelect::EnsureWidgetTree()
{
	if (!WidgetTree || RootColumn)
	{
		return;
	}

	RootColumn = WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass(), TEXT("DiffRoot"));
	WidgetTree->RootWidget = RootColumn;

	HeaderText = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("DiffHeader"));
	HeaderText->SetText(FText::FromString(TEXT("SELECT DIFFICULTY")));
	HeaderText->SetFont(DiffFont(36, true));
	HeaderText->SetColorAndOpacity(DiffGold());
	if (UVerticalBoxSlot* BoxSlot = RootColumn->AddChildToVerticalBox(HeaderText))
	{
		BoxSlot->SetHorizontalAlignment(HAlign_Center);
		BoxSlot->SetPadding(FMargin(0.0f, 64.0f, 0.0f, 32.0f));
	}

	ListBox = WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass(), TEXT("DiffList"));
	if (UVerticalBoxSlot* BoxSlot = RootColumn->AddChildToVerticalBox(ListBox))
	{
		BoxSlot->SetHorizontalAlignment(HAlign_Center);
		BoxSlot->SetPadding(FMargin(0.0f, 8.0f));
	}

	BackButton = WidgetTree->ConstructWidget<UButton>(UButton::StaticClass(), TEXT("DiffBack"));
	UTextBlock* BackLabel =
		WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("DiffBackLabel"));
	BackLabel->SetText(FText::FromString(TEXT("Back")));
	BackLabel->SetFont(DiffFont(20, true));
	BackLabel->SetColorAndOpacity(DiffCream());
	BackButton->AddChild(BackLabel);
	BackButton->OnClicked.AddDynamic(this, &UShockDifficultySelect::OnBackClicked);
	if (UVerticalBoxSlot* BoxSlot = RootColumn->AddChildToVerticalBox(BackButton))
	{
		BoxSlot->SetHorizontalAlignment(HAlign_Center);
		BoxSlot->SetPadding(FMargin(0.0f, 32.0f, 0.0f, 8.0f));
	}
}

TSharedRef<SWidget> UShockDifficultySelect::RebuildWidget()
{
	EnsureWidgetTree();
	return Super::RebuildWidget();
}

void UShockDifficultySelect::NativeConstruct()
{
	EnsureWidgetTree();
	Super::NativeConstruct();
}

void UShockDifficultySelect::RebuildList()
{
	EnsureWidgetTree();
	EnsureTextures();
	if (!ListBox)
	{
		return;
	}
	ListBox->ClearChildren();
	SelectedIndex = FMath::Clamp(SelectedIndex, 0, 3);
	for (int32 i = 0; i < 4; ++i)
	{
		UShockDifficultySelectRow* Row =
			CreateWidget<UShockDifficultySelectRow>(this, UShockDifficultySelectRow::StaticClass());
		if (!Row)
		{
			continue;
		}
		Row->Configure(this, i, IndexToDiff(i), i == SelectedIndex, ChevronTexture);
		if (UVerticalBoxSlot* BoxSlot = ListBox->AddChildToVerticalBox(Row))
		{
			BoxSlot->SetPadding(FMargin(4.0f, 10.0f));
			BoxSlot->SetHorizontalAlignment(HAlign_Left);
		}
	}
}

void UShockDifficultySelect::OpenDifficultySelect()
{
	bOpen = true;
	SelectedIndex = 1;
	EnsureWidgetTree();
	RebuildList();
	SetVisibility(ESlateVisibility::Visible);
	SetKeyboardFocus();
}

void UShockDifficultySelect::CloseDifficultySelect()
{
	bOpen = false;
	SetVisibility(ESlateVisibility::Collapsed);
}

void UShockDifficultySelect::SetSelectedIndex(int32 Index)
{
	SelectedIndex = FMath::Clamp(Index, 0, 3);
	if (bOpen)
	{
		RebuildList();
	}
}

void UShockDifficultySelect::ConfirmSelection()
{
	const EShockDifficulty Diff = IndexToDiff(SelectedIndex);
	LastConfirmedDifficulty = Diff;
	LastTravelRequestMap = FirstLevelPath;

	UWorld* World = GetWorld();
	UShockGameInstance* GI = UShockGameInstance::GetShockInstance(World);
	if (!GI && World)
	{
		GI = UShockGameInstance::GetShockInstanceForVerify(World);
	}
	if (GI)
	{
		GI->SetSelectedDifficulty(Diff);
		GI->RequestTravelToLevel(this, FirstLevelPath, TravelOptions);
	}
	else
	{
		// Headless editor worlds may still use the default GameInstance — record travel locally.
		UE_LOG(
			LogTemp,
			Display,
			TEXT("BIOSHOCK_DIFFICULTY no ShockGameInstance — recorded travel locally map=%s"),
			*FirstLevelPath);
	}

	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_NEWGAME difficulty=%s map=%s"),
		ShockDifficultyText::DisplayName(Diff),
		*FirstLevelPath);
}

void UShockDifficultySelect::HandleRowClicked(int32 Index)
{
	SetSelectedIndex(Index);
	ConfirmSelection();
}

void UShockDifficultySelect::OnBackClicked()
{
	CloseDifficultySelect();
}

FReply UShockDifficultySelect::NativeOnKeyDown(const FGeometry& InGeometry, const FKeyEvent& InKeyEvent)
{
	if (!bOpen)
	{
		return Super::NativeOnKeyDown(InGeometry, InKeyEvent);
	}
	const FKey Key = InKeyEvent.GetKey();
	if (Key == EKeys::Escape)
	{
		CloseDifficultySelect();
		return FReply::Handled();
	}
	if (Key == EKeys::Up || Key == EKeys::Gamepad_DPad_Up)
	{
		SetSelectedIndex(SelectedIndex <= 0 ? 3 : SelectedIndex - 1);
		return FReply::Handled();
	}
	if (Key == EKeys::Down || Key == EKeys::Gamepad_DPad_Down)
	{
		SetSelectedIndex(SelectedIndex >= 3 ? 0 : SelectedIndex + 1);
		return FReply::Handled();
	}
	if (Key == EKeys::Enter || Key == EKeys::Gamepad_FaceButton_Bottom)
	{
		ConfirmSelection();
		return FReply::Handled();
	}
	return Super::NativeOnKeyDown(InGeometry, InKeyEvent);
}

bool UShockDifficultySelect::RunHeadlessDifficultyVerify(UObject* WorldContextObject)
{
	LastVerifyError.Empty();
	UWorld* World = GEngine
		? GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::ReturnNull)
		: nullptr;
	if (!World)
	{
		LastVerifyError = TEXT("no world");
		return false;
	}

	UShockGameInstance* GI = UShockGameInstance::GetShockInstance(World);
	const bool bWasSuppress = GI ? GI->bSuppressLevelTravel : false;
	if (GI)
	{
		GI->bSuppressLevelTravel = true;
		GI->LastTravelRequestMap.Empty();
	}

	UShockDifficultySelect* Menu =
		CreateWidget<UShockDifficultySelect>(World, UShockDifficultySelect::StaticClass());
	if (!Menu)
	{
		if (GI)
		{
			GI->bSuppressLevelTravel = bWasSuppress;
		}
		LastVerifyError = TEXT("CreateWidget difficulty failed");
		return false;
	}

	Menu->OpenDifficultySelect();
	if (Menu->GetOptionCount() != 4)
	{
		if (GI)
		{
			GI->bSuppressLevelTravel = bWasSuppress;
		}
		LastVerifyError = TEXT("expected 4 difficulty options");
		Menu->CloseDifficultySelect();
		return false;
	}

	Menu->SetSelectedIndex(2); // Hard
	Menu->ConfirmSelection();

	if (Menu->GetLastConfirmedDifficulty() != EShockDifficulty::Hard)
	{
		if (GI)
		{
			GI->bSuppressLevelTravel = bWasSuppress;
		}
		LastVerifyError = TEXT("difficulty not confirmed as Hard");
		Menu->CloseDifficultySelect();
		return false;
	}
	if (!Menu->GetLastTravelRequestMap().Contains(TEXT("1-Medical")))
	{
		if (GI)
		{
			GI->bSuppressLevelTravel = bWasSuppress;
		}
		LastVerifyError = FString::Printf(
			TEXT("travel not initiated (map=%s)"), *Menu->GetLastTravelRequestMap());
		Menu->CloseDifficultySelect();
		return false;
	}
	if (GI && GI->GetSelectedDifficulty() != EShockDifficulty::Hard)
	{
		GI->bSuppressLevelTravel = bWasSuppress;
		LastVerifyError = TEXT("GI difficulty not set to Hard after confirm");
		Menu->CloseDifficultySelect();
		return false;
	}

	Menu->CloseDifficultySelect();
	if (GI)
	{
		GI->bSuppressLevelTravel = bWasSuppress;
	}
	return true;
}
