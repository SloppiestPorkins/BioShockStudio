#include "ShockWeaponSelectScreen.h"

#include "ShockElectroBoltPlasmid.h"
#include "ShockIncineratePlasmid.h"
#include "ShockPlasmid.h"
#include "ShockPlayer.h"
#include "ShockWeapon.h"

#include "Blueprint/WidgetTree.h"
#include "Components/Button.h"
#include "Components/ScrollBox.h"
#include "Components/TextBlock.h"
#include "Components/VerticalBox.h"
#include "Components/VerticalBoxSlot.h"
#include "Engine/Engine.h"
#include "Engine/World.h"
#include "GameFramework/PlayerController.h"
#include "Input/Events.h"
#include "InputCoreTypes.h"
#include "Kismet/GameplayStatics.h"
#include "Styling/CoreStyle.h"

FString UShockWeaponSelectScreen::LastSelectVerifyError;

namespace
{
FSlateFontInfo SelectFont(int32 Size, bool bBold = false)
{
	return FCoreStyle::GetDefaultFontStyle(bBold ? TEXT("Bold") : TEXT("Regular"), Size);
}

FLinearColor SelectGold() { return FLinearColor(0.92f, 0.78f, 0.35f, 1.0f); }
FLinearColor SelectCream() { return FLinearColor(0.92f, 0.88f, 0.75f, 1.0f); }
}

void UShockSelectListRow::Configure(UShockWeaponSelectScreen* InOwner, int32 InRowIndex, const FString& Label)
{
	OwnerScreen = InOwner;
	RowIndex = InRowIndex;
	PendingLabel = Label;
	if (RowText)
	{
		RowText->SetText(FText::FromString(
			FString::Printf(TEXT("[%d]  %s"), RowIndex + 1, *PendingLabel)));
	}
}

TSharedRef<SWidget> UShockSelectListRow::RebuildWidget()
{
	if (WidgetTree && !RowButton)
	{
		RowButton = WidgetTree->ConstructWidget<UButton>(UButton::StaticClass(), TEXT("RowButton"));
		WidgetTree->RootWidget = RowButton;
		RowText = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("RowText"));
		RowText->SetFont(SelectFont(18));
		RowText->SetColorAndOpacity(SelectCream());
		if (!PendingLabel.IsEmpty())
		{
			RowText->SetText(FText::FromString(
				FString::Printf(TEXT("[%d]  %s"), RowIndex + 1, *PendingLabel)));
		}
		RowButton->AddChild(RowText);
		RowButton->OnClicked.AddDynamic(this, &UShockSelectListRow::HandleClicked);
	}
	return Super::RebuildWidget();
}

void UShockSelectListRow::HandleClicked()
{
	if (UShockWeaponSelectScreen* Owner = OwnerScreen.Get())
	{
		Owner->HandleRowClicked(RowIndex);
	}
}

UShockWeaponSelectScreen::UShockWeaponSelectScreen(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
	SetVisibility(ESlateVisibility::Collapsed);
	SetIsFocusable(true);
}

FString UShockWeaponSelectScreen::GetLastSelectVerifyError()
{
	return LastSelectVerifyError;
}

void UShockWeaponSelectScreen::BindDisplayPlayer(AShockPlayer* Player)
{
	DisplayPlayerOverride = Player;
}

AShockPlayer* UShockWeaponSelectScreen::ResolvePlayer() const
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

FString UShockWeaponSelectScreen::GetListedItemLabel(int32 Index) const
{
	return ListedLabels.IsValidIndex(Index) ? ListedLabels[Index] : FString();
}

void UShockWeaponSelectScreen::EnsureWidgetTree()
{
	if (!WidgetTree || RootColumn)
	{
		return;
	}

	RootColumn = WidgetTree->ConstructWidget<UVerticalBox>(
		UVerticalBox::StaticClass(), TEXT("SelectRoot"));
	WidgetTree->RootWidget = RootColumn;

	TitleText = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("SelectTitle"));
	TitleText->SetFont(SelectFont(28, true));
	TitleText->SetColorAndOpacity(SelectGold());
	TitleText->SetText(FText::FromString(TEXT("Weapons & Plasmids")));
	TitleText->SetJustification(ETextJustify::Center);
	if (UVerticalBoxSlot* TitleSlot = RootColumn->AddChildToVerticalBox(TitleText))
	{
		TitleSlot->SetPadding(FMargin(24.0f, 48.0f, 24.0f, 16.0f));
		TitleSlot->SetHorizontalAlignment(HAlign_Center);
	}

	ListScroll = WidgetTree->ConstructWidget<UScrollBox>(UScrollBox::StaticClass(), TEXT("SelectScroll"));
	ListBox = WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass(), TEXT("SelectList"));
	ListScroll->AddChild(ListBox);
	if (UVerticalBoxSlot* ScrollSlot = RootColumn->AddChildToVerticalBox(ListScroll))
	{
		ScrollSlot->SetPadding(FMargin(80.0f, 8.0f, 80.0f, 48.0f));
		ScrollSlot->SetSize(FSlateChildSize(ESlateSizeRule::Fill));
	}
}

TSharedRef<SWidget> UShockWeaponSelectScreen::RebuildWidget()
{
	EnsureWidgetTree();
	return Super::RebuildWidget();
}

void UShockWeaponSelectScreen::NativeConstruct()
{
	Super::NativeConstruct();
	EnsureWidgetTree();
}

void UShockWeaponSelectScreen::SetPaused(bool bPause)
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

void UShockWeaponSelectScreen::RebuildList()
{
	EnsureWidgetTree();
	ListedKinds.Reset();
	ListedSlots.Reset();
	ListedLabels.Reset();

	if (ListBox)
	{
		ListBox->ClearChildren();
	}

	AShockPlayer* Player = ResolvePlayer();
	if (!Player || !ListBox || !WidgetTree)
	{
		return;
	}

	for (int32 SlotIndex = 0; SlotIndex < Player->WeaponSlots.Num(); ++SlotIndex)
	{
		AShockWeapon* W = Player->WeaponSlots[SlotIndex].Get();
		if (!W)
		{
			continue;
		}
		FString Name = W->GetWeaponDefName().IsNone()
			? FString()
			: W->GetWeaponDefName().ToString();
		if (Name.IsEmpty())
		{
			Name = W->GetClass() ? W->GetClass()->GetName() : FString::Printf(TEXT("Weapon %d"), SlotIndex + 1);
		}
		FString Detail = Name;
		if (W->bEnforceAmmo)
		{
			Detail += FString::Printf(
				TEXT("   ammo %d / %d"), W->GetRoundsInMagazine(), W->GetReserveAmmo());
		}
		ListedKinds.Add(EListedKind::Weapon);
		ListedSlots.Add(SlotIndex);
		ListedLabels.Add(Detail);
	}

	for (int32 SlotIndex = 0; SlotIndex < Player->EquippedPlasmids.Num(); ++SlotIndex)
	{
		UShockPlasmid* P = Player->EquippedPlasmids[SlotIndex].Get();
		if (!P)
		{
			continue;
		}
		FString Name = P->PlasmidName.ToString();
		if (Name.IsEmpty())
		{
			Name = FString::Printf(TEXT("Plasmid %d"), SlotIndex + 1);
		}
		const FString Detail = FString::Printf(
			TEXT("%s   EVE %d"), *Name, FMath::RoundToInt(P->EveCost));
		ListedKinds.Add(EListedKind::Plasmid);
		ListedSlots.Add(SlotIndex);
		ListedLabels.Add(Detail);
	}

	for (int32 RowIndex = 0; RowIndex < ListedLabels.Num(); ++RowIndex)
	{
		UShockSelectListRow* Row = CreateWidget<UShockSelectListRow>(this, UShockSelectListRow::StaticClass());
		if (!Row)
		{
			continue;
		}
		Row->Configure(this, RowIndex, ListedLabels[RowIndex]);
		if (UVerticalBoxSlot* RowSlot = ListBox->AddChildToVerticalBox(Row))
		{
			RowSlot->SetPadding(FMargin(4.0f, 4.0f));
		}
	}
}

bool UShockWeaponSelectScreen::EquipListedItem(int32 Index)
{
	AShockPlayer* Player = ResolvePlayer();
	if (!Player || !ListedKinds.IsValidIndex(Index) || !ListedSlots.IsValidIndex(Index))
	{
		return false;
	}
	const int32 SlotIndex = ListedSlots[Index];
	if (ListedKinds[Index] == EListedKind::Weapon)
	{
		return Player->SelectWeaponSlot(SlotIndex);
	}
	return Player->SelectPlasmidSlot(SlotIndex);
}

bool UShockWeaponSelectScreen::EquipByNumberKey(int32 OneBased)
{
	return EquipListedItem(OneBased - 1);
}

void UShockWeaponSelectScreen::HandleRowClicked(int32 Index)
{
	if (EquipListedItem(Index))
	{
		CloseSelectScreen();
	}
}

void UShockWeaponSelectScreen::OpenSelectScreen()
{
	bOpen = true;
	EnsureWidgetTree();
	RebuildList();
	SetVisibility(ESlateVisibility::Visible);
	SetPaused(true);
	SetKeyboardFocus();
}

void UShockWeaponSelectScreen::CloseSelectScreen()
{
	bOpen = false;
	SetVisibility(ESlateVisibility::Collapsed);
	if (bDidPause)
	{
		SetPaused(false);
	}
}

FReply UShockWeaponSelectScreen::NativeOnKeyDown(const FGeometry& InGeometry, const FKeyEvent& InKeyEvent)
{
	if (!bOpen)
	{
		return Super::NativeOnKeyDown(InGeometry, InKeyEvent);
	}

	const FKey Key = InKeyEvent.GetKey();
	if (Key == EKeys::Escape || Key == EKeys::LeftShift || Key == EKeys::RightShift)
	{
		CloseSelectScreen();
		return FReply::Handled();
	}

	static const FKey NumberKeys[] = {
		EKeys::One, EKeys::Two, EKeys::Three, EKeys::Four, EKeys::Five,
		EKeys::Six, EKeys::Seven, EKeys::Eight, EKeys::Nine,
	};
	for (int32 i = 0; i < UE_ARRAY_COUNT(NumberKeys); ++i)
	{
		if (Key == NumberKeys[i])
		{
			if (EquipByNumberKey(i + 1))
			{
				CloseSelectScreen();
			}
			return FReply::Handled();
		}
	}

	return Super::NativeOnKeyDown(InGeometry, InKeyEvent);
}

bool UShockWeaponSelectScreen::RunHeadlessSelectVerify(UObject* WorldContextObject)
{
	LastSelectVerifyError.Empty();

	UWorld* World = GEngine
		? GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::ReturnNull)
		: nullptr;
	if (!World)
	{
		LastSelectVerifyError = TEXT("no world");
		return false;
	}

	const FVector SpawnLoc(160.0f, 60.0f, 100.0f);
	FActorSpawnParameters Params;
	Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;

	AShockPlayer* Player = World->SpawnActor<AShockPlayer>(
		AShockPlayer::StaticClass(), SpawnLoc, FRotator::ZeroRotator, Params);
	if (!Player)
	{
		LastSelectVerifyError = TEXT("spawn player failed");
		return false;
	}

	Player->GiveWeaponByDef(TEXT("Wrench"), 0);
	Player->GiveWeaponByDef(TEXT("Pistol"), 1);
	Player->EquipPlasmid(UShockElectroBoltPlasmid::StaticClass(), 0);
	Player->EquipPlasmid(UShockIncineratePlasmid::StaticClass(), 1);

	UShockWeaponSelectScreen* Screen = CreateWidget<UShockWeaponSelectScreen>(
		World, UShockWeaponSelectScreen::StaticClass());
	if (!Screen)
	{
		LastSelectVerifyError = TEXT("CreateWidget select failed");
		Player->Destroy();
		return false;
	}

	Screen->BindDisplayPlayer(Player);
	Screen->EnsureWidgetTree();
	Screen->RebuildList();

	if (Screen->GetListedItemCount() != 4)
	{
		LastSelectVerifyError = FString::Printf(
			TEXT("listed items %d != 4"), Screen->GetListedItemCount());
		Screen->RemoveFromParent();
		Player->Destroy();
		return false;
	}

	if (!Screen->EquipListedItem(1))
	{
		LastSelectVerifyError = TEXT("EquipListedItem(1) pistol failed");
		Screen->RemoveFromParent();
		Player->Destroy();
		return false;
	}
	if (Player->GetActiveWeaponSlot() != 1)
	{
		LastSelectVerifyError = FString::Printf(
			TEXT("after select equip weapon active=%d want=1"), Player->GetActiveWeaponSlot());
		Screen->RemoveFromParent();
		Player->Destroy();
		return false;
	}

	if (!Screen->EquipListedItem(3))
	{
		LastSelectVerifyError = TEXT("EquipListedItem(3) incinerate failed");
		Screen->RemoveFromParent();
		Player->Destroy();
		return false;
	}
	if (Player->ActivePlasmidSlot != 1)
	{
		LastSelectVerifyError = FString::Printf(
			TEXT("after select equip plasmid active=%d want=1"), Player->ActivePlasmidSlot);
		Screen->RemoveFromParent();
		Player->Destroy();
		return false;
	}

	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_SELECT_OK listed=4 equip_weapon=1 equip_plasmid=1"));

	Screen->RemoveFromParent();
	Player->Destroy();
	return true;
}
