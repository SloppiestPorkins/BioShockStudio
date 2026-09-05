#include "ShockSaveLoadMenu.h"

#include "ShockCarryState.h"
#include "ShockDecoStyle.h"
#include "ShockGameInstance.h"
#include "ShockPlayer.h"
#include "ShockSaveGame.h"

#include "Blueprint/WidgetTree.h"
#include "Components/Border.h"
#include "Components/Button.h"
#include "Components/HorizontalBox.h"
#include "Components/HorizontalBoxSlot.h"
#include "Components/Image.h"
#include "Components/Overlay.h"
#include "Components/OverlaySlot.h"
#include "Components/ScrollBox.h"
#include "Components/TextBlock.h"
#include "Components/VerticalBox.h"
#include "Components/VerticalBoxSlot.h"
#include "Engine/Engine.h"
#include "Engine/World.h"
#include "Input/Events.h"
#include "InputCoreTypes.h"
#include "Kismet/GameplayStatics.h"
#include "Misc/DateTime.h"
#include "Styling/CoreStyle.h"

FString UShockSaveLoadMenu::LastVerifyError;

namespace
{
FSlateFontInfo SaveFont(int32 Size, bool bBold = false)
{
	return FCoreStyle::GetDefaultFontStyle(bBold ? TEXT("Bold") : TEXT("Regular"), Size);
}

FLinearColor SaveGold() { return FLinearColor(0.92f, 0.78f, 0.35f, 1.0f); }
FLinearColor SaveCream() { return FLinearColor(0.92f, 0.88f, 0.75f, 1.0f); }
}

void UShockSaveLoadSlotRow::Configure(
	UShockSaveLoadMenu* InOwner,
	int32 InSlotIndex,
	const FString& Title,
	const FString& Subtitle,
	bool bEmpty,
	bool bSelected)
{
	OwnerMenu = InOwner;
	SlotIndex = InSlotIndex;
	PendingTitle = Title;
	PendingSub = Subtitle;
	bPendingEmpty = bEmpty;
	bPendingSelected = bSelected;

	if (TitleText)
	{
		TitleText->SetText(FText::FromString(PendingTitle));
		TitleText->SetColorAndOpacity(
			bPendingEmpty ? UShockDecoStyle::DimColor()
						  : (bPendingSelected ? SaveGold() : SaveCream()));
	}
	if (SubText)
	{
		SubText->SetText(FText::FromString(PendingSub));
		SubText->SetColorAndOpacity(
			bPendingEmpty ? UShockDecoStyle::EmptySlotTint()
						  : FLinearColor(0.65f, 0.7f, 0.75f, 1.0f));
	}
	if (ThumbBox)
	{
		ThumbBox->SetBrushColor(
			bPendingEmpty ? FLinearColor(0.08f, 0.1f, 0.12f, 1.0f)
						  : FLinearColor(0.15f, 0.22f, 0.28f, 1.0f));
	}
	if (PlateImage)
	{
		UShockDecoStyle::ApplyRowPlate(PlateImage, FVector2D(640.0f, 72.0f));
		PlateImage->SetColorAndOpacity(
			bPendingEmpty ? UShockDecoStyle::EmptySlotTint() : FLinearColor::White);
	}
	if (RowButton)
	{
		UShockDecoStyle::ApplyListButtonStyle(RowButton, bPendingSelected && !bPendingEmpty);
	}
}

TSharedRef<SWidget> UShockSaveLoadSlotRow::RebuildWidget()
{
	if (WidgetTree && !RowButton)
	{
		RowButton = WidgetTree->ConstructWidget<UButton>(UButton::StaticClass(), TEXT("SaveRowButton"));
		WidgetTree->RootWidget = RowButton;

		RowOverlay = WidgetTree->ConstructWidget<UOverlay>(UOverlay::StaticClass(), TEXT("SaveRowOverlay"));
		PlateImage = WidgetTree->ConstructWidget<UImage>(UImage::StaticClass(), TEXT("SavePlate"));
		UShockDecoStyle::ApplyRowPlate(PlateImage, FVector2D(640.0f, 72.0f));
		if (UOverlaySlot* PlateSlot = RowOverlay->AddChildToOverlay(PlateImage))
		{
			PlateSlot->SetHorizontalAlignment(HAlign_Fill);
			PlateSlot->SetVerticalAlignment(VAlign_Fill);
		}

		RowBox = WidgetTree->ConstructWidget<UHorizontalBox>(UHorizontalBox::StaticClass(), TEXT("SaveRowBox"));

		ThumbBox = WidgetTree->ConstructWidget<UBorder>(UBorder::StaticClass(), TEXT("SaveThumb"));
		ThumbBox->SetBrushColor(FLinearColor(0.08f, 0.1f, 0.12f, 1.0f));
		ThumbBox->SetPadding(FMargin(40.0f, 28.0f));
		UTextBlock* ThumbLabel =
			WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("SaveThumbLabel"));
		ThumbLabel->SetText(FText::FromString(TEXT("")));
		ThumbBox->AddChild(ThumbLabel);

		UVerticalBox* Labels =
			WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass(), TEXT("SaveLabels"));
		TitleText = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("SaveTitle"));
		TitleText->SetFont(SaveFont(20, true));
		TitleText->SetColorAndOpacity(SaveCream());
		TitleText->SetText(FText::FromString(PendingTitle));
		SubText = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("SaveSub"));
		SubText->SetFont(SaveFont(14, false));
		SubText->SetColorAndOpacity(FLinearColor(0.65f, 0.7f, 0.75f, 1.0f));
		SubText->SetText(FText::FromString(PendingSub));
		Labels->AddChildToVerticalBox(TitleText);
		Labels->AddChildToVerticalBox(SubText);

		if (UHorizontalBoxSlot* ThumbSlot = RowBox->AddChildToHorizontalBox(ThumbBox))
		{
			ThumbSlot->SetPadding(FMargin(4.0f, 4.0f, 16.0f, 4.0f));
			ThumbSlot->SetVerticalAlignment(VAlign_Center);
		}
		if (UHorizontalBoxSlot* TextSlot = RowBox->AddChildToHorizontalBox(Labels))
		{
			TextSlot->SetVerticalAlignment(VAlign_Center);
		}
		if (UOverlaySlot* BoxSlot = RowOverlay->AddChildToOverlay(RowBox))
		{
			BoxSlot->SetHorizontalAlignment(HAlign_Fill);
			BoxSlot->SetVerticalAlignment(VAlign_Center);
			BoxSlot->SetPadding(FMargin(12.0f, 6.0f));
		}
		RowButton->AddChild(RowOverlay);
		UShockDecoStyle::ApplyListButtonStyle(RowButton, bPendingSelected);
		RowButton->OnClicked.AddDynamic(this, &UShockSaveLoadSlotRow::HandleClicked);
	}
	return Super::RebuildWidget();
}

void UShockSaveLoadSlotRow::HandleClicked()
{
	if (UShockSaveLoadMenu* Owner = OwnerMenu.Get())
	{
		Owner->HandleSlotClicked(SlotIndex);
	}
}

UShockSaveLoadMenu::UShockSaveLoadMenu(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
	SetVisibility(ESlateVisibility::Collapsed);
	SetIsFocusable(true);
}

FString UShockSaveLoadMenu::GetLastSaveLoadVerifyError()
{
	return LastVerifyError;
}

void UShockSaveLoadMenu::BindDisplayPlayer(AShockPlayer* Player)
{
	DisplayPlayerOverride = Player;
}

AShockPlayer* UShockSaveLoadMenu::ResolvePlayer() const
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

FString UShockSaveLoadMenu::ResolveCurrentLevelPath() const
{
	if (UWorld* World = GetWorld())
	{
		return World->GetOutermost() ? World->GetOutermost()->GetName() : FString();
	}
	return FString();
}

FString UShockSaveLoadMenu::PrettyLevelName(const FString& PackagePath) const
{
	FString Name = PackagePath;
	int32 Slash = INDEX_NONE;
	if (Name.FindLastChar(TEXT('/'), Slash))
	{
		Name = Name.Mid(Slash + 1);
	}
	return Name.IsEmpty() ? TEXT("Unknown") : Name;
}

void UShockSaveLoadMenu::EnsureWidgetTree()
{
	if (!WidgetTree || RootColumn)
	{
		return;
	}

	RootColumn = WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass(), TEXT("SaveRoot"));
	WidgetTree->RootWidget = RootColumn;

	HeaderBanner = WidgetTree->ConstructWidget<UImage>(UImage::StaticClass(), TEXT("SaveBanner"));
	UShockDecoStyle::ApplyBanner(HeaderBanner, FVector2D(420.0f, 88.0f));
	if (UVerticalBoxSlot* BannerSlot = RootColumn->AddChildToVerticalBox(HeaderBanner))
	{
		BannerSlot->SetHorizontalAlignment(HAlign_Center);
		BannerSlot->SetPadding(FMargin(0.0f, 48.0f, 0.0f, 4.0f));
	}

	HeaderText = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("SaveHeader"));
	HeaderText->SetFont(SaveFont(28, true));
	HeaderText->SetColorAndOpacity(SaveGold());
	if (UVerticalBoxSlot* BoxSlot = RootColumn->AddChildToVerticalBox(HeaderText))
	{
		BoxSlot->SetHorizontalAlignment(HAlign_Center);
		BoxSlot->SetPadding(FMargin(0.0f, 4.0f, 0.0f, 16.0f));
	}

	SlotScroll = WidgetTree->ConstructWidget<UScrollBox>(UScrollBox::StaticClass(), TEXT("SaveScroll"));
	SlotList = WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass(), TEXT("SaveList"));
	SlotScroll->AddChild(SlotList);
	if (UVerticalBoxSlot* BoxSlot = RootColumn->AddChildToVerticalBox(SlotScroll))
	{
		BoxSlot->SetHorizontalAlignment(HAlign_Center);
		BoxSlot->SetPadding(FMargin(40.0f, 8.0f));
	}

	BackButton = WidgetTree->ConstructWidget<UButton>(UButton::StaticClass(), TEXT("SaveBack"));
	UTextBlock* BackLabel =
		WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("SaveBackLabel"));
	BackLabel->SetText(FText::FromString(TEXT("Back")));
	BackLabel->SetFont(SaveFont(20, true));
	BackLabel->SetColorAndOpacity(SaveCream());
	BackButton->AddChild(BackLabel);
	UShockDecoStyle::ApplyListButtonStyle(BackButton, false);
	BackButton->OnClicked.AddDynamic(this, &UShockSaveLoadMenu::OnBackClicked);
	if (UVerticalBoxSlot* BoxSlot = RootColumn->AddChildToVerticalBox(BackButton))
	{
		BoxSlot->SetHorizontalAlignment(HAlign_Center);
		BoxSlot->SetPadding(FMargin(0.0f, 24.0f));
	}
}

TSharedRef<SWidget> UShockSaveLoadMenu::RebuildWidget()
{
	EnsureWidgetTree();
	return Super::RebuildWidget();
}

void UShockSaveLoadMenu::NativeConstruct()
{
	EnsureWidgetTree();
	Super::NativeConstruct();
}

void UShockSaveLoadMenu::RefreshSlotList()
{
	EnsureWidgetTree();
	if (HeaderText)
	{
		HeaderText->SetText(FText::FromString(
			Mode == EShockSaveLoadMode::Save ? TEXT("SAVE GAME") : TEXT("LOAD GAME")));
	}
	if (!SlotList)
	{
		return;
	}
	SlotList->ClearChildren();
	SelectedSlot = FMath::Clamp(SelectedSlot, 0, UShockSaveGame::MaxSlots - 1);

	for (int32 i = 0; i < UShockSaveGame::MaxSlots; ++i)
	{
		const FString SlotName = UShockSaveGame::MakeSlotName(i);
		const bool bExists = UGameplayStatics::DoesSaveGameExist(SlotName, 0);
		FString Title = FString::Printf(TEXT("Slot %d"), i + 1);
		FString Sub = TEXT("Empty");
		if (bExists)
		{
			if (UShockSaveGame* Loaded =
					Cast<UShockSaveGame>(UGameplayStatics::LoadGameFromSlot(SlotName, 0)))
			{
				Title = Loaded->LevelDisplayName.IsEmpty()
					? PrettyLevelName(Loaded->LevelPackagePath)
					: Loaded->LevelDisplayName;
				Sub = FString::Printf(
					TEXT("%s  -  %s"),
					*Loaded->GetTimestampDisplay(),
					ShockDifficultyText::DisplayName(Loaded->Difficulty));
			}
		}

		UShockSaveLoadSlotRow* Row =
			CreateWidget<UShockSaveLoadSlotRow>(this, UShockSaveLoadSlotRow::StaticClass());
		if (!Row)
		{
			continue;
		}
		Row->Configure(this, i, Title, Sub, !bExists, i == SelectedSlot);
		if (UVerticalBoxSlot* BoxSlot = SlotList->AddChildToVerticalBox(Row))
		{
			BoxSlot->SetPadding(FMargin(4.0f, 6.0f));
		}
	}
}

void UShockSaveLoadMenu::OpenSaveLoad(EShockSaveLoadMode InMode)
{
	Mode = InMode;
	bOpen = true;
	SelectedSlot = 0;
	EnsureWidgetTree();
	RefreshSlotList();
	SetVisibility(ESlateVisibility::Visible);
	SetKeyboardFocus();
}

void UShockSaveLoadMenu::CloseSaveLoad()
{
	bOpen = false;
	SetVisibility(ESlateVisibility::Collapsed);
}

void UShockSaveLoadMenu::SetSelectedSlot(int32 Index)
{
	SelectedSlot = FMath::Clamp(Index, 0, UShockSaveGame::MaxSlots - 1);
	if (bOpen)
	{
		RefreshSlotList();
	}
}

bool UShockSaveLoadMenu::SaveToSlot(int32 SlotIndex, UShockCarryState* CarryOverride)
{
	UShockCarryState* Carry = CarryOverride;
	TObjectPtr<UShockCarryState> Captured;
	if (!Carry)
	{
		if (AShockPlayer* Player = ResolvePlayer())
		{
			Captured = UShockCarryState::Capture(Player);
			Carry = Captured;
		}
	}
	if (!Carry)
	{
		UE_LOG(LogTemp, Warning, TEXT("BIOSHOCK_SAVE fail reason=no_carry"));
		return false;
	}

	UShockSaveGame* Save = Cast<UShockSaveGame>(
		UGameplayStatics::CreateSaveGameObject(UShockSaveGame::StaticClass()));
	if (!Save)
	{
		return false;
	}

	EShockDifficulty Diff = EShockDifficulty::Medium;
	if (UShockGameInstance* GI = UShockGameInstance::GetShockInstance(GetWorld()))
	{
		Diff = GI->GetSelectedDifficulty();
	}

	Save->CaptureFromCarryState(Carry, Diff);
	Save->LevelPackagePath = ResolveCurrentLevelPath();
	if (Save->LevelPackagePath.IsEmpty())
	{
		Save->LevelPackagePath = TEXT("/Game/BioShockSlice/1-Medical");
	}
	Save->LevelDisplayName = PrettyLevelName(Save->LevelPackagePath);
	Save->SavedUtcTicks = FDateTime::UtcNow().GetTicks();
	Save->SlotDisplayName = FString::Printf(TEXT("Slot %d"), SlotIndex + 1);

	const FString SlotName = UShockSaveGame::MakeSlotName(SlotIndex);
	const bool bOk = UGameplayStatics::SaveGameToSlot(Save, SlotName, 0);
	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_SAVE slot=%s ok=%d level=%s money=%d"),
		*SlotName,
		bOk ? 1 : 0,
		*Save->LevelPackagePath,
		Save->Money);
	return bOk;
}

UShockSaveGame* UShockSaveLoadMenu::LoadFromSlot(int32 SlotIndex) const
{
	const FString SlotName = UShockSaveGame::MakeSlotName(SlotIndex);
	if (!UGameplayStatics::DoesSaveGameExist(SlotName, 0))
	{
		return nullptr;
	}
	return Cast<UShockSaveGame>(UGameplayStatics::LoadGameFromSlot(SlotName, 0));
}

bool UShockSaveLoadMenu::ActivateSelectedSlot()
{
	if (Mode == EShockSaveLoadMode::Save)
	{
		const bool bOk = SaveToSlot(SelectedSlot, nullptr);
		if (bOk)
		{
			RefreshSlotList();
		}
		return bOk;
	}

	UShockSaveGame* Loaded = LoadFromSlot(SelectedSlot);
	if (!Loaded)
	{
		UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_LOAD empty slot=%d"), SelectedSlot);
		return false;
	}

	UShockCarryState* Carry = Loaded->RestoreToCarryState(this);
	if (UShockGameInstance* GI = UShockGameInstance::GetShockInstance(GetWorld()))
	{
		GI->SetSelectedDifficulty(Loaded->Difficulty);
		GI->SetPendingCarry(Carry, FName(*Loaded->ArrivalStartLabel));
		const bool bWasSuppress = GI->bSuppressLevelTravel;
		// Always record; respect suppress for actual OpenLevel.
		GI->RequestTravelToLevel(this, Loaded->LevelPackagePath);
		(void)bWasSuppress;
	}

	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_LOAD slot=%d level=%s money=%d"),
		SelectedSlot,
		*Loaded->LevelPackagePath,
		Loaded->Money);
	return true;
}

void UShockSaveLoadMenu::HandleSlotClicked(int32 Index)
{
	SetSelectedSlot(Index);
	ActivateSelectedSlot();
}

void UShockSaveLoadMenu::OnBackClicked()
{
	CloseSaveLoad();
}

FReply UShockSaveLoadMenu::NativeOnKeyDown(const FGeometry& InGeometry, const FKeyEvent& InKeyEvent)
{
	if (!bOpen)
	{
		return Super::NativeOnKeyDown(InGeometry, InKeyEvent);
	}
	const FKey Key = InKeyEvent.GetKey();
	if (Key == EKeys::Escape)
	{
		CloseSaveLoad();
		return FReply::Handled();
	}
	if (Key == EKeys::Up || Key == EKeys::Gamepad_DPad_Up)
	{
		SetSelectedSlot(SelectedSlot <= 0 ? UShockSaveGame::MaxSlots - 1 : SelectedSlot - 1);
		return FReply::Handled();
	}
	if (Key == EKeys::Down || Key == EKeys::Gamepad_DPad_Down)
	{
		SetSelectedSlot(
			SelectedSlot >= UShockSaveGame::MaxSlots - 1 ? 0 : SelectedSlot + 1);
		return FReply::Handled();
	}
	if (Key == EKeys::Enter || Key == EKeys::Gamepad_FaceButton_Bottom)
	{
		ActivateSelectedSlot();
		return FReply::Handled();
	}
	return Super::NativeOnKeyDown(InGeometry, InKeyEvent);
}

bool UShockSaveLoadMenu::RunHeadlessSaveLoadVerify(UObject* WorldContextObject)
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

	UShockCarryState* Carry = NewObject<UShockCarryState>();
	Carry->Health = 77.5f;
	Carry->MaxEve = 120.0f;
	Carry->CurrentEve = 55.0f;
	Carry->Money = 314;
	Carry->ActiveWeaponSlot = 1;
	Carry->ArrivalStartLabel = TEXT("MedicalStart");
	FShockCarriedWeapon W;
	W.DefName = FName(TEXT("Pistol"));
	W.Slot = 1;
	W.Mag = 6;
	W.Reserve = 48;
	Carry->Weapons.Add(W);

	UShockSaveLoadMenu* Menu =
		CreateWidget<UShockSaveLoadMenu>(World, UShockSaveLoadMenu::StaticClass());
	if (!Menu)
	{
		LastVerifyError = TEXT("CreateWidget save/load failed");
		return false;
	}

	Menu->OpenSaveLoad(EShockSaveLoadMode::Save);
	const int32 Slot = 7; // high slot to avoid clobbering player saves in PIE
	if (!Menu->SaveToSlot(Slot, Carry))
	{
		LastVerifyError = TEXT("SaveToSlot failed");
		Menu->CloseSaveLoad();
		return false;
	}

	UShockSaveGame* Loaded = Menu->LoadFromSlot(Slot);
	if (!Loaded)
	{
		LastVerifyError = TEXT("LoadFromSlot returned null");
		Menu->CloseSaveLoad();
		return false;
	}

	UShockCarryState* Restored = Loaded->RestoreToCarryState(Menu);
	if (!Restored
		|| !FMath::IsNearlyEqual(Restored->Health, 77.5f)
		|| Restored->Money != 314
		|| Restored->Weapons.Num() != 1
		|| Restored->Weapons[0].DefName != FName(TEXT("Pistol"))
		|| Restored->Weapons[0].Reserve != 48
		|| Restored->ArrivalStartLabel != TEXT("MedicalStart"))
	{
		LastVerifyError = TEXT("carry state round-trip mismatch");
		Menu->CloseSaveLoad();
		return false;
	}

	// Cleanup test slot.
	UGameplayStatics::DeleteGameInSlot(UShockSaveGame::MakeSlotName(Slot), 0);
	Menu->CloseSaveLoad();
	return true;
}
