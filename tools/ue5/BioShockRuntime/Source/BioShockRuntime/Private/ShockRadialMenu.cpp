#include "ShockRadialMenu.h"

#include "ShockElectroBoltPlasmid.h"
#include "ShockIncineratePlasmid.h"
#include "ShockPlasmid.h"
#include "ShockPlayer.h"
#include "ShockWeapon.h"

#include "Blueprint/WidgetTree.h"
#include "Components/CanvasPanel.h"
#include "Components/CanvasPanelSlot.h"
#include "Components/HorizontalBox.h"
#include "Components/HorizontalBoxSlot.h"
#include "Components/Image.h"
#include "Components/TextBlock.h"
#include "Engine/Engine.h"
#include "Engine/Texture2D.h"
#include "Engine/World.h"
#include "GameFramework/PlayerController.h"
#include "Styling/CoreStyle.h"

FString UShockRadialMenu::LastRadialVerifyError;

namespace
{
constexpr float RingSize = 420.0f;
constexpr float SegmentRingSize = 64.0f;
constexpr float SegmentRadius = 155.0f;
constexpr float StatDigitW = 22.0f;
constexpr float StatDigitH = 44.0f;
constexpr int32 MaxStatDigits = 4;

const TCHAR* RadialRingPath = TEXT("/Game/BioShockUI/Radial/T_Radial_BrassRing.T_Radial_BrassRing");

FString RadialDigitPath(int32 Digit)
{
	return FString::Printf(
		TEXT("/Game/BioShockUI/Radial/T_Radial_Digit_%d.T_Radial_Digit_%d"), Digit, Digit);
}

FSlateFontInfo RadialFont(int32 Size, bool bBold = false)
{
	return FCoreStyle::GetDefaultFontStyle(bBold ? TEXT("Bold") : TEXT("Regular"), Size);
}

FLinearColor Gold() { return FLinearColor(0.92f, 0.78f, 0.35f, 1.0f); }
FLinearColor DimGold() { return FLinearColor(0.55f, 0.45f, 0.22f, 0.85f); }
FLinearColor White() { return FLinearColor(0.95f, 0.95f, 0.95f, 1.0f); }
}

UShockRadialMenu::UShockRadialMenu(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
	SetVisibility(ESlateVisibility::Collapsed);
}

FString UShockRadialMenu::GetLastRadialVerifyError()
{
	return LastRadialVerifyError;
}

void UShockRadialMenu::BindDisplayPlayer(AShockPlayer* Player)
{
	DisplayPlayerOverride = Player;
}

AShockPlayer* UShockRadialMenu::ResolvePlayer() const
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

int32 UShockRadialMenu::GetHoveredSlotIndex() const
{
	if (!SegmentSlotIndices.IsValidIndex(HoveredSegment))
	{
		return -1;
	}
	return SegmentSlotIndices[HoveredSegment];
}

void UShockRadialMenu::EnsureTextures()
{
	if (!RingTexture)
	{
		RingTexture = LoadObject<UTexture2D>(nullptr, RadialRingPath);
	}
	for (int32 Digit = 0; Digit < 10; ++Digit)
	{
		if (!DigitTextures[Digit])
		{
			DigitTextures[Digit] = LoadObject<UTexture2D>(nullptr, *RadialDigitPath(Digit));
		}
	}
	if (RingImage && RingTexture)
	{
		RingImage->SetBrushFromTexture(RingTexture, true);
		RingImage->SetBrushSize(FVector2D(RingSize, RingSize));
	}
}

bool UShockRadialMenu::HasRingTexture() const
{
	return RingImage && RingImage->GetBrush().GetResourceObject() != nullptr;
}

bool UShockRadialMenu::HasDigitTextures() const
{
	for (int32 Digit = 0; Digit < 10; ++Digit)
	{
		if (DigitTextures[Digit])
		{
			return true;
		}
	}
	return false;
}

void UShockRadialMenu::EnsureWidgetTree()
{
	if (!WidgetTree || RootCanvas)
	{
		return;
	}

	RootCanvas = WidgetTree->ConstructWidget<UCanvasPanel>(UCanvasPanel::StaticClass(), TEXT("RadialCanvas"));
	WidgetTree->RootWidget = RootCanvas;

	RingImage = WidgetTree->ConstructWidget<UImage>(UImage::StaticClass(), TEXT("RadialRing"));
	RingImage->SetColorAndOpacity(FLinearColor(1.0f, 1.0f, 1.0f, 0.92f));
	if (UCanvasPanelSlot* RingSlot = RootCanvas->AddChildToCanvas(RingImage))
	{
		RingSlot->SetAnchors(FAnchors(0.5f, 0.5f));
		RingSlot->SetAlignment(FVector2D(0.5f, 0.5f));
		RingSlot->SetAutoSize(true);
		RingSlot->SetPosition(FVector2D::ZeroVector);
	}

	CenterNameText = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("CenterName"));
	CenterNameText->SetFont(RadialFont(22, true));
	CenterNameText->SetColorAndOpacity(Gold());
	CenterNameText->SetJustification(ETextJustify::Center);
	if (UCanvasPanelSlot* NameSlot = RootCanvas->AddChildToCanvas(CenterNameText))
	{
		NameSlot->SetAnchors(FAnchors(0.5f, 0.5f));
		NameSlot->SetAlignment(FVector2D(0.5f, 1.0f));
		NameSlot->SetAutoSize(true);
		NameSlot->SetPosition(FVector2D(0.0f, -8.0f));
	}

	CenterStatDigits = WidgetTree->ConstructWidget<UHorizontalBox>(
		UHorizontalBox::StaticClass(), TEXT("CenterStatDigits"));
	CenterStatDigitImages.Reset();
	for (int32 i = 0; i < MaxStatDigits; ++i)
	{
		UImage* Dig = WidgetTree->ConstructWidget<UImage>(
			UImage::StaticClass(), *FString::Printf(TEXT("StatDigit_%d"), i));
		Dig->SetVisibility(ESlateVisibility::Collapsed);
		if (UHorizontalBoxSlot* HS = CenterStatDigits->AddChildToHorizontalBox(Dig))
		{
			HS->SetPadding(FMargin(1.0f, 0.0f));
			HS->SetVerticalAlignment(VAlign_Center);
		}
		CenterStatDigitImages.Add(Dig);
	}
	if (UCanvasPanelSlot* StatSlot = RootCanvas->AddChildToCanvas(CenterStatDigits))
	{
		StatSlot->SetAnchors(FAnchors(0.5f, 0.5f));
		StatSlot->SetAlignment(FVector2D(0.5f, 0.0f));
		StatSlot->SetAutoSize(true);
		StatSlot->SetPosition(FVector2D(0.0f, 8.0f));
	}
}

TSharedRef<SWidget> UShockRadialMenu::RebuildWidget()
{
	EnsureWidgetTree();
	return Super::RebuildWidget();
}

void UShockRadialMenu::NativeConstruct()
{
	Super::NativeConstruct();
	EnsureWidgetTree();
	EnsureTextures();
}

void UShockRadialMenu::NativeDestruct()
{
	bOpen = false;
	Super::NativeDestruct();
}

void UShockRadialMenu::SetDigitString(
	UHorizontalBox* Box,
	const TArray<TObjectPtr<UImage>>& Slots,
	const FString& Digits) const
{
	if (!Box)
	{
		return;
	}
	const FString Trimmed = Digits.Left(Slots.Num());
	for (int32 i = 0; i < Slots.Num(); ++i)
	{
		UImage* Img = Slots[i].Get();
		if (!Img)
		{
			continue;
		}
		if (i >= Trimmed.Len())
		{
			Img->SetVisibility(ESlateVisibility::Collapsed);
			continue;
		}
		const TCHAR Ch = Trimmed[i];
		if (Ch < TEXT('0') || Ch > TEXT('9'))
		{
			Img->SetVisibility(ESlateVisibility::Collapsed);
			continue;
		}
		const int32 Digit = Ch - TEXT('0');
		if (DigitTextures[Digit])
		{
			Img->SetBrushFromTexture(DigitTextures[Digit], true);
			Img->SetBrushSize(FVector2D(StatDigitW, StatDigitH));
			Img->SetVisibility(ESlateVisibility::HitTestInvisible);
		}
		else
		{
			Img->SetVisibility(ESlateVisibility::Collapsed);
		}
	}
}

void UShockRadialMenu::RebuildSegments()
{
	EnsureWidgetTree();
	EnsureTextures();

	for (UTextBlock* Label : SegmentLabels)
	{
		if (Label)
		{
			Label->RemoveFromParent();
		}
	}
	for (UImage* SegRing : SegmentRings)
	{
		if (SegRing)
		{
			SegRing->RemoveFromParent();
		}
	}
	SegmentLabels.Reset();
	SegmentRings.Reset();
	SegmentSlotIndices.Reset();

	AShockPlayer* Player = ResolvePlayer();
	if (!Player || !RootCanvas)
	{
		return;
	}

	if (Mode == EShockRadialMode::Weapon)
	{
		for (int32 SlotIndex = 0; SlotIndex < Player->WeaponSlots.Num(); ++SlotIndex)
		{
			if (Player->WeaponSlots[SlotIndex].Get())
			{
				SegmentSlotIndices.Add(SlotIndex);
			}
		}
	}
	else
	{
		for (int32 SlotIndex = 0; SlotIndex < Player->EquippedPlasmids.Num(); ++SlotIndex)
		{
			if (Player->EquippedPlasmids[SlotIndex].Get())
			{
				SegmentSlotIndices.Add(SlotIndex);
			}
		}
	}

	const int32 Count = SegmentSlotIndices.Num();
	if (Count <= 0)
	{
		HoveredSegment = 0;
		RefreshCenterReadout();
		return;
	}

	HoveredSegment = FMath::Clamp(HoveredSegment, 0, Count - 1);

	for (int32 Seg = 0; Seg < Count; ++Seg)
	{
		const int32 SlotIndex = SegmentSlotIndices[Seg];
		FString LabelStr;
		if (Mode == EShockRadialMode::Weapon)
		{
			if (AShockWeapon* W = Player->WeaponSlots[SlotIndex].Get())
			{
				const FName DefName = W->GetWeaponDefName();
				LabelStr = DefName.IsNone() ? FString() : DefName.ToString();
				if (LabelStr.IsEmpty())
				{
					LabelStr = W->GetClass() ? W->GetClass()->GetName() : FString::Printf(TEXT("Weapon %d"), SlotIndex + 1);
				}
			}
		}
		else if (UShockPlasmid* P = Player->EquippedPlasmids[SlotIndex].Get())
		{
			LabelStr = P->PlasmidName.ToString();
			if (LabelStr.IsEmpty())
			{
				LabelStr = FString::Printf(TEXT("Plasmid %d"), SlotIndex + 1);
			}
		}

		const float AngleDeg = (360.0f * Seg / static_cast<float>(Count)) - 90.0f;
		const float Rad = FMath::DegreesToRadians(AngleDeg);
		const FVector2D Pos(FMath::Cos(Rad) * SegmentRadius, FMath::Sin(Rad) * SegmentRadius);

		UImage* SegRing = WidgetTree->ConstructWidget<UImage>(
			UImage::StaticClass(), *FString::Printf(TEXT("SegRing_%d"), Seg));
		if (RingTexture)
		{
			SegRing->SetBrushFromTexture(RingTexture, true);
			SegRing->SetBrushSize(FVector2D(SegmentRingSize, SegmentRingSize));
		}
		SegRing->SetColorAndOpacity(DimGold());
		if (UCanvasPanelSlot* RS = RootCanvas->AddChildToCanvas(SegRing))
		{
			RS->SetAnchors(FAnchors(0.5f, 0.5f));
			RS->SetAlignment(FVector2D(0.5f, 0.5f));
			RS->SetAutoSize(true);
			RS->SetPosition(Pos);
		}
		SegmentRings.Add(SegRing);

		UTextBlock* Label = WidgetTree->ConstructWidget<UTextBlock>(
			UTextBlock::StaticClass(), *FString::Printf(TEXT("SegLabel_%d"), Seg));
		Label->SetFont(RadialFont(14, true));
		Label->SetColorAndOpacity(White());
		Label->SetText(FText::FromString(LabelStr));
		Label->SetJustification(ETextJustify::Center);
		if (UCanvasPanelSlot* LS = RootCanvas->AddChildToCanvas(Label))
		{
			LS->SetAnchors(FAnchors(0.5f, 0.5f));
			LS->SetAlignment(FVector2D(0.5f, 0.5f));
			LS->SetAutoSize(true);
			LS->SetPosition(Pos);
		}
		SegmentLabels.Add(Label);
	}

	ApplySegmentVisuals();
	RefreshCenterReadout();
}

void UShockRadialMenu::ApplySegmentVisuals()
{
	for (int32 Seg = 0; Seg < SegmentLabels.Num(); ++Seg)
	{
		const bool bHover = Seg == HoveredSegment;
		if (UTextBlock* Label = SegmentLabels[Seg].Get())
		{
			Label->SetColorAndOpacity(bHover ? Gold() : White());
			Label->SetFont(RadialFont(bHover ? 16 : 14, true));
		}
		if (UImage* SegRing = SegmentRings.IsValidIndex(Seg) ? SegmentRings[Seg].Get() : nullptr)
		{
			SegRing->SetColorAndOpacity(bHover ? Gold() : DimGold());
			const float Size = bHover ? SegmentRingSize * 1.15f : SegmentRingSize;
			SegRing->SetBrushSize(FVector2D(Size, Size));
		}
	}
}

void UShockRadialMenu::RefreshCenterReadout()
{
	CachedCenterName.Empty();
	CachedCenterStat.Empty();

	AShockPlayer* Player = ResolvePlayer();
	const int32 SlotIndex = GetHoveredSlotIndex();
	if (!Player || SlotIndex < 0)
	{
		if (CenterNameText)
		{
			CenterNameText->SetText(FText::GetEmpty());
		}
		SetDigitString(CenterStatDigits, CenterStatDigitImages, FString());
		return;
	}

	if (Mode == EShockRadialMode::Weapon)
	{
		if (AShockWeapon* W = Player->WeaponSlots[SlotIndex].Get())
		{
			const FName DefName = W->GetWeaponDefName();
			CachedCenterName = DefName.IsNone() ? FString() : DefName.ToString();
			if (CachedCenterName.IsEmpty() && W->GetClass())
			{
				CachedCenterName = W->GetClass()->GetName();
			}
			if (W->bEnforceAmmo)
			{
				CachedCenterStat = FString::FromInt(W->GetRoundsInMagazine());
			}
		}
	}
	else if (UShockPlasmid* P = Player->EquippedPlasmids[SlotIndex].Get())
	{
		CachedCenterName = P->PlasmidName.ToString();
		CachedCenterStat = FString::FromInt(FMath::RoundToInt(P->EveCost));
	}

	if (CenterNameText)
	{
		CenterNameText->SetText(FText::FromString(CachedCenterName));
	}
	SetDigitString(CenterStatDigits, CenterStatDigitImages, CachedCenterStat);
}

void UShockRadialMenu::SetHoveredSegmentIndex(int32 SegmentIndex)
{
	if (SegmentSlotIndices.Num() <= 0)
	{
		HoveredSegment = 0;
		return;
	}
	HoveredSegment = FMath::Clamp(SegmentIndex, 0, SegmentSlotIndices.Num() - 1);
	ApplySegmentVisuals();
	RefreshCenterReadout();
}

void UShockRadialMenu::StepHoveredSegment(int32 Delta)
{
	if (SegmentSlotIndices.Num() <= 0)
	{
		return;
	}
	const int32 Count = SegmentSlotIndices.Num();
	HoveredSegment = (HoveredSegment + Delta % Count + Count) % Count;
	ApplySegmentVisuals();
	RefreshCenterReadout();
}

void UShockRadialMenu::UpdateHoverFromMouse()
{
	if (!bOpen || SegmentSlotIndices.Num() <= 0)
	{
		return;
	}

	APlayerController* PC = GetOwningPlayer();
	if (!PC)
	{
		return;
	}

	float MouseX = 0.0f;
	float MouseY = 0.0f;
	if (!PC->GetMousePosition(MouseX, MouseY))
	{
		return;
	}

	int32 SizeX = 0;
	int32 SizeY = 0;
	PC->GetViewportSize(SizeX, SizeY);
	if (SizeX <= 0 || SizeY <= 0)
	{
		return;
	}

	const float Dx = MouseX - SizeX * 0.5f;
	const float Dy = MouseY - SizeY * 0.5f;
	if (FMath::Sqrt(Dx * Dx + Dy * Dy) < 24.0f)
	{
		return;
	}

	// Screen Y grows downward; atan2(Dy, Dx) with 0 at +X, convert so 0 = top (-90 deg).
	float AngleDeg = FMath::RadiansToDegrees(FMath::Atan2(Dy, Dx)) + 90.0f;
	if (AngleDeg < 0.0f)
	{
		AngleDeg += 360.0f;
	}
	const float SegSpan = 360.0f / static_cast<float>(SegmentSlotIndices.Num());
	const int32 Seg = FMath::Clamp(
		FMath::FloorToInt(AngleDeg / SegSpan), 0, SegmentSlotIndices.Num() - 1);
	if (Seg != HoveredSegment)
	{
		SetHoveredSegmentIndex(Seg);
	}
}

void UShockRadialMenu::OpenRadial(EShockRadialMode InMode)
{
	Mode = InMode;
	bOpen = true;
	EnsureWidgetTree();
	EnsureTextures();
	RebuildSegments();

	// Prefer current equipped as initial hover.
	if (AShockPlayer* Player = ResolvePlayer())
	{
		const int32 Wanted = (Mode == EShockRadialMode::Weapon)
			? Player->GetActiveWeaponSlot()
			: Player->ActivePlasmidSlot;
		const int32 Found = SegmentSlotIndices.IndexOfByKey(Wanted);
		if (Found != INDEX_NONE)
		{
			SetHoveredSegmentIndex(Found);
		}
	}

	SetVisibility(ESlateVisibility::HitTestInvisible);
}

void UShockRadialMenu::ForceOpenForCapture(EShockRadialMode InMode)
{
	OpenRadial(InMode);
	SetVisibility(ESlateVisibility::HitTestInvisible);
}

void UShockRadialMenu::CloseRadial(bool bEquipHovered)
{
	if (bEquipHovered)
	{
		if (AShockPlayer* Player = ResolvePlayer())
		{
			const int32 SlotIndex = GetHoveredSlotIndex();
			if (SlotIndex >= 0)
			{
				if (Mode == EShockRadialMode::Weapon)
				{
					Player->SelectWeaponSlot(SlotIndex);
				}
				else
				{
					Player->SelectPlasmidSlot(SlotIndex);
				}
			}
		}
	}
	bOpen = false;
	SetVisibility(ESlateVisibility::Collapsed);
}

void UShockRadialMenu::NativeTick(const FGeometry& MyGeometry, float InDeltaTime)
{
	Super::NativeTick(MyGeometry, InDeltaTime);
	if (bOpen)
	{
		UpdateHoverFromMouse();
	}
}

bool UShockRadialMenu::RunHeadlessRadialVerify(UObject* WorldContextObject)
{
	LastRadialVerifyError.Empty();

	UWorld* World = GEngine
		? GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::ReturnNull)
		: nullptr;
	if (!World)
	{
		LastRadialVerifyError = TEXT("no world");
		return false;
	}

	const FVector SpawnLoc(140.0f, 40.0f, 100.0f);
	FActorSpawnParameters Params;
	Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;

	AShockPlayer* Player = World->SpawnActor<AShockPlayer>(
		AShockPlayer::StaticClass(), SpawnLoc, FRotator::ZeroRotator, Params);
	if (!Player)
	{
		LastRadialVerifyError = TEXT("spawn player failed");
		return false;
	}

	Player->GiveWeaponByDef(TEXT("Wrench"), 0);
	Player->GiveWeaponByDef(TEXT("Pistol"), 1);
	Player->GiveWeaponByDef(TEXT("Shotgun"), 3);
	Player->EquipPlasmid(UShockElectroBoltPlasmid::StaticClass(), 0);
	Player->EquipPlasmid(UShockIncineratePlasmid::StaticClass(), 1);

	UShockRadialMenu* Radial = CreateWidget<UShockRadialMenu>(World, UShockRadialMenu::StaticClass());
	if (!Radial)
	{
		LastRadialVerifyError = TEXT("CreateWidget radial failed");
		Player->Destroy();
		return false;
	}

	Radial->BindDisplayPlayer(Player);
	Radial->OpenRadial(EShockRadialMode::Weapon);
	Radial->EnsureTextures();

	if (!Radial->HasRingTexture())
	{
		LastRadialVerifyError = TEXT(
			"radial ring texture null — run import_bioshock_ui.py into /Game/BioShockUI/Radial");
		Radial->RemoveFromParent();
		Player->Destroy();
		return false;
	}
	if (!Radial->HasDigitTextures())
	{
		LastRadialVerifyError = TEXT(
			"radial digit textures missing — run import_bioshock_ui.py into /Game/BioShockUI/Radial");
		Radial->RemoveFromParent();
		Player->Destroy();
		return false;
	}
	if (Radial->GetSegmentCount() != 3)
	{
		LastRadialVerifyError = FString::Printf(
			TEXT("weapon radial segments %d != 3"), Radial->GetSegmentCount());
		Radial->RemoveFromParent();
		Player->Destroy();
		return false;
	}

	// Hover pistol segment (slot 1) and release-equip.
	int32 PistolSeg = INDEX_NONE;
	for (int32 Seg = 0; Seg < Radial->GetSegmentCount(); ++Seg)
	{
		Radial->SetHoveredSegmentIndex(Seg);
		if (Radial->GetHoveredSlotIndex() == 1)
		{
			PistolSeg = Seg;
			break;
		}
	}
	if (PistolSeg == INDEX_NONE)
	{
		LastRadialVerifyError = TEXT("pistol slot missing from segments");
		Radial->RemoveFromParent();
		Player->Destroy();
		return false;
	}
	Radial->SetHoveredSegmentIndex(PistolSeg);
	Radial->CloseRadial(true);
	if (Player->GetActiveWeaponSlot() != 1)
	{
		LastRadialVerifyError = FString::Printf(
			TEXT("SelectWeaponSlot after radial release: active=%d want=1"),
			Player->GetActiveWeaponSlot());
		Radial->RemoveFromParent();
		Player->Destroy();
		return false;
	}

	Radial->OpenRadial(EShockRadialMode::Plasmid);
	if (Radial->GetSegmentCount() != 2)
	{
		LastRadialVerifyError = FString::Printf(
			TEXT("plasmid radial segments %d != 2"), Radial->GetSegmentCount());
		Radial->RemoveFromParent();
		Player->Destroy();
		return false;
	}
	Radial->SetHoveredSegmentIndex(1);
	Radial->CloseRadial(true);
	if (Player->ActivePlasmidSlot != 1)
	{
		LastRadialVerifyError = FString::Printf(
			TEXT("SelectPlasmidSlot after radial release: active=%d want=1"),
			Player->ActivePlasmidSlot);
		Radial->RemoveFromParent();
		Player->Destroy();
		return false;
	}

	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_RADIAL_OK weapon_segs=3 plasmid_segs=2 ring=1 digits=1 equip_weapon=1 equip_plasmid=1"));

	Radial->RemoveFromParent();
	Player->Destroy();
	return true;
}
