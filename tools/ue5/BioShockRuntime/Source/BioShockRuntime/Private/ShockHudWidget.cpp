#include "ShockHudWidget.h"

#include "ShockDamageLibrary.h"
#include "ShockPlasmid.h"
#include "ShockPlayer.h"
#include "ShockPawn.h"
#include "ShockWeapon.h"

#include "Blueprint/WidgetTree.h"
#include "Components/Border.h"
#include "Components/CanvasPanel.h"
#include "Components/CanvasPanelSlot.h"
#include "Components/HorizontalBox.h"
#include "Components/HorizontalBoxSlot.h"
#include "Components/Image.h"
#include "Components/Overlay.h"
#include "Components/OverlaySlot.h"
#include "Components/TextBlock.h"
#include "Components/VerticalBox.h"
#include "Components/VerticalBoxSlot.h"
#include "Engine/Texture2D.h"
#include "Engine/World.h"
#include "GameFramework/PlayerController.h"
#include "TimerManager.h"

FString UShockHudWidget::LastHudVerifyError;

namespace
{
constexpr float RefreshIntervalSeconds = 0.1f;
constexpr float DamageFlashSeconds = 0.35f;
constexpr float MeterImageWidth = 260.0f;
constexpr float MeterImageHeight = 72.0f;
constexpr float PlasmidRingSize = 72.0f;
constexpr float WeaponIconSize = 48.0f;

const TCHAR* HealthArcTexturePath = TEXT("/Game/BioShockUI/HUD/T_Hud_HealthArc.T_Hud_HealthArc");
const TCHAR* EveArcTexturePath = TEXT("/Game/BioShockUI/HUD/T_Hud_EveArc.T_Hud_EveArc");
const TCHAR* MeterUnderlayTexturePath =
	TEXT("/Game/BioShockUI/HUD/T_Hud_MeterUnderlay.T_Hud_MeterUnderlay");

FLinearColor HudGold() { return FLinearColor(0.92f, 0.78f, 0.35f, 1.0f); }
FLinearColor HudWhite() { return FLinearColor(0.95f, 0.95f, 0.95f, 1.0f); }
FLinearColor HudRed() { return FLinearColor(0.95f, 0.15f, 0.12f, 1.0f); }
FLinearColor HudDecoChrome() { return FLinearColor(0.55f, 0.48f, 0.32f, 0.85f); }
FLinearColor HudTransparent() { return FLinearColor(0.0f, 0.0f, 0.0f, 0.0f); }

FSlateFontInfo MakeHudFont(int32 Size, bool bBold = false)
{
	// Decoded Scaleform fonts (HUDPC Century Gothic / LHF Bell Boy) export as glyph PNGs, not
	// a UE FontFace — use engine face sized like BioShock's Deco HUD numerals until a FontFace
	// import lands.
	return FCoreStyle::GetDefaultFontStyle(bBold ? TEXT("Bold") : TEXT("Regular"), Size);
}

UImage* MakeMeterImage(UWidgetTree* Tree, FName Name)
{
	UImage* Image = Tree->ConstructWidget<UImage>(UImage::StaticClass(), Name);
	Image->SetBrushSize(FVector2D(MeterImageWidth, MeterImageHeight));
	Image->SetVisibility(ESlateVisibility::HitTestInvisible);
	return Image;
}

UBorder* MakeDecoCapSlot(UWidgetTree* Tree, FName Name, const FLinearColor& Fill)
{
	// Medical-cross / hypo frame bitmaps are Scaleform tag-512 in sharedlibrary — Deco UBorder
	// stand-in until tag-512 decode exists.
	UBorder* Cap = Tree->ConstructWidget<UBorder>(UBorder::StaticClass(), Name);
	Cap->SetBrushColor(Fill);
	Cap->SetPadding(FMargin(2.0f));
	Cap->SetDesiredSizeScale(FVector2D(1.0f, 1.0f));
	return Cap;
}

UTextBlock* MakeCapGlyph(UWidgetTree* Tree, FName Name, const FString& Glyph, const FLinearColor& Color)
{
	UTextBlock* Text = Tree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), Name);
	Text->SetText(FText::FromString(Glyph));
	Text->SetFont(MakeHudFont(16, true));
	Text->SetColorAndOpacity(FSlateColor(Color));
	Text->SetJustification(ETextJustify::Center);
	return Text;
}

bool BrushHasTexture(const UImage* Image)
{
	if (!Image)
	{
		return false;
	}
	const FSlateBrush& Brush = Image->GetBrush();
	return Brush.GetResourceObject() != nullptr;
}

UCanvasPanelSlot* AnchorBottomLeft(UCanvasPanel* Canvas, UWidget* Child, const FVector2D& Position)
{
	UCanvasPanelSlot* Slot = Canvas->AddChildToCanvas(Child);
	Slot->SetAnchors(FAnchors(0.0f, 1.0f, 0.0f, 1.0f));
	Slot->SetAlignment(FVector2D(0.0f, 1.0f));
	Slot->SetAutoSize(true);
	Slot->SetPosition(Position);
	return Slot;
}

UCanvasPanelSlot* AnchorTopLeft(UCanvasPanel* Canvas, UWidget* Child, const FVector2D& Position)
{
	UCanvasPanelSlot* Slot = Canvas->AddChildToCanvas(Child);
	Slot->SetAnchors(FAnchors(0.0f, 0.0f, 0.0f, 0.0f));
	Slot->SetAlignment(FVector2D(0.0f, 0.0f));
	Slot->SetAutoSize(true);
	Slot->SetPosition(Position);
	return Slot;
}

UCanvasPanelSlot* AnchorCenter(UCanvasPanel* Canvas, UWidget* Child)
{
	UCanvasPanelSlot* Slot = Canvas->AddChildToCanvas(Child);
	Slot->SetAnchors(FAnchors(0.5f, 0.5f, 0.5f, 0.5f));
	Slot->SetAlignment(FVector2D(0.5f, 0.5f));
	Slot->SetAutoSize(true);
	Slot->SetPosition(FVector2D(0.0f, 0.0f));
	return Slot;
}
}

UShockHudWidget::UShockHudWidget(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
}

FString UShockHudWidget::GetLastHudVerifyError()
{
	return LastHudVerifyError;
}

void UShockHudWidget::BindDisplayPlayer(AShockPlayer* Player)
{
	DisplayPlayerOverride = Player;
}

void UShockHudWidget::EnsureHudTextures()
{
	if (!HealthArcTexture)
	{
		HealthArcTexture = LoadObject<UTexture2D>(nullptr, HealthArcTexturePath);
	}
	if (!EveArcTexture)
	{
		EveArcTexture = LoadObject<UTexture2D>(nullptr, EveArcTexturePath);
	}
	if (!MeterUnderlayTexture)
	{
		MeterUnderlayTexture = LoadObject<UTexture2D>(nullptr, MeterUnderlayTexturePath);
	}

	if (HealthArcImage && HealthArcTexture)
	{
		HealthArcImage->SetBrushFromTexture(HealthArcTexture, true);
		HealthArcImage->SetBrushSize(FVector2D(MeterImageWidth, MeterImageHeight));
	}
	if (EveArcImage && EveArcTexture)
	{
		EveArcImage->SetBrushFromTexture(EveArcTexture, true);
		EveArcImage->SetBrushSize(FVector2D(MeterImageWidth, MeterImageHeight));
	}
	if (MeterUnderlayImage && MeterUnderlayTexture)
	{
		MeterUnderlayImage->SetBrushFromTexture(MeterUnderlayTexture, true);
		MeterUnderlayImage->SetBrushSize(FVector2D(MeterImageWidth, MeterImageHeight));
		MeterUnderlayImage->SetColorAndOpacity(FLinearColor(1.0f, 1.0f, 1.0f, 0.85f));
	}
}

void UShockHudWidget::EnsureWidgetTree()
{
	if (!WidgetTree || HealthText)
	{
		return;
	}

	UCanvasPanel* Canvas = WidgetTree->ConstructWidget<UCanvasPanel>(
		UCanvasPanel::StaticClass(), TEXT("HudCanvas"));
	WidgetTree->RootWidget = Canvas;

	// --- Top-left objective ---
	ObjectiveText = WidgetTree->ConstructWidget<UTextBlock>(
		UTextBlock::StaticClass(), TEXT("ObjectiveText"));
	ObjectiveText->SetText(FText::GetEmpty());
	ObjectiveText->SetFont(MakeHudFont(18));
	ObjectiveText->SetColorAndOpacity(FSlateColor(HudGold()));
	ObjectiveText->SetVisibility(ESlateVisibility::Collapsed);
	AnchorTopLeft(Canvas, ObjectiveText, FVector2D(28.0f, 24.0f));

	// --- Center crosshair (per-weapon reticle sprites are ImportAssets stubs / tag-512) ---
	CrosshairText = WidgetTree->ConstructWidget<UTextBlock>(
		UTextBlock::StaticClass(), TEXT("CrosshairText"));
	CrosshairText->SetText(FText::FromString(TEXT("+")));
	CrosshairText->SetFont(MakeHudFont(22));
	CrosshairText->SetColorAndOpacity(FSlateColor(FLinearColor(0.95f, 0.95f, 0.95f, 0.75f)));
	CrosshairText->SetJustification(ETextJustify::Center);
	AnchorCenter(Canvas, CrosshairText);

	// --- Bottom-left floating cluster (no black backing box) ---
	UHorizontalBox* BottomLeft = WidgetTree->ConstructWidget<UHorizontalBox>(
		UHorizontalBox::StaticClass(), TEXT("BottomLeftCluster"));
	AnchorBottomLeft(Canvas, BottomLeft, FVector2D(20.0f, -18.0f));

	// Plasmid ring + EVE-cost numeral (sunburst stand-in), above/ beside meters
	UVerticalBox* PlasmidColumn = WidgetTree->ConstructWidget<UVerticalBox>(
		UVerticalBox::StaticClass(), TEXT("PlasmidColumn"));
	if (UHorizontalBoxSlot* PlasmidColSlot = BottomLeft->AddChildToHorizontalBox(PlasmidColumn))
	{
		PlasmidColSlot->SetVerticalAlignment(VAlign_Bottom);
		PlasmidColSlot->SetPadding(FMargin(0.0f, 0.0f, 10.0f, 36.0f));
	}

	PlasmidRing = WidgetTree->ConstructWidget<UBorder>(UBorder::StaticClass(), TEXT("PlasmidRing"));
	PlasmidRing->SetBrushColor(HudDecoChrome());
	PlasmidRing->SetPadding(FMargin(6.0f));
	{
		UOverlay* PlasmidOverlay = WidgetTree->ConstructWidget<UOverlay>(
			UOverlay::StaticClass(), TEXT("PlasmidOverlay"));
		PlasmidRing->SetContent(PlasmidOverlay);

		PlasmidIconImage = WidgetTree->ConstructWidget<UImage>(
			UImage::StaticClass(), TEXT("PlasmidIconImage"));
		PlasmidIconImage->SetBrushSize(FVector2D(PlasmidRingSize - 16.0f, PlasmidRingSize - 16.0f));
		PlasmidIconImage->SetColorAndOpacity(FLinearColor(0.15f, 0.12f, 0.08f, 0.65f));
		PlasmidIconImage->SetVisibility(ESlateVisibility::HitTestInvisible);
		if (UOverlaySlot* IconSlot = PlasmidOverlay->AddChildToOverlay(PlasmidIconImage))
		{
			IconSlot->SetHorizontalAlignment(HAlign_Center);
			IconSlot->SetVerticalAlignment(VAlign_Center);
		}

		EveCostText = WidgetTree->ConstructWidget<UTextBlock>(
			UTextBlock::StaticClass(), TEXT("EveCostText"));
		EveCostText->SetText(FText::GetEmpty());
		EveCostText->SetFont(MakeHudFont(26, true));
		EveCostText->SetColorAndOpacity(FSlateColor(HudGold()));
		EveCostText->SetJustification(ETextJustify::Center);
		if (UOverlaySlot* CostSlot = PlasmidOverlay->AddChildToOverlay(EveCostText))
		{
			CostSlot->SetHorizontalAlignment(HAlign_Center);
			CostSlot->SetVerticalAlignment(VAlign_Center);
		}
	}
	if (UVerticalBoxSlot* RingSlot = PlasmidColumn->AddChildToVerticalBox(PlasmidRing))
	{
		RingSlot->SetHorizontalAlignment(HAlign_Center);
		RingSlot->SetPadding(FMargin(0.0f, 0.0f, 0.0f, 4.0f));
	}

	PlasmidText = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("PlasmidText"));
	PlasmidText->SetText(FText::GetEmpty());
	PlasmidText->SetFont(MakeHudFont(11));
	PlasmidText->SetColorAndOpacity(FSlateColor(FLinearColor(1.0f, 0.72f, 0.35f, 0.9f)));
	PlasmidText->SetVisibility(ESlateVisibility::Collapsed);
	if (UVerticalBoxSlot* PlasmidNameSlot = PlasmidColumn->AddChildToVerticalBox(PlasmidText))
	{
		PlasmidNameSlot->SetHorizontalAlignment(HAlign_Center);
	}

	// Health + EVE stacked meters with left-end cap slots
	UVerticalBox* MetersColumn = WidgetTree->ConstructWidget<UVerticalBox>(
		UVerticalBox::StaticClass(), TEXT("MetersColumn"));
	if (UHorizontalBoxSlot* MetersSlot = BottomLeft->AddChildToHorizontalBox(MetersColumn))
	{
		MetersSlot->SetVerticalAlignment(VAlign_Bottom);
		MetersSlot->SetPadding(FMargin(0.0f, 0.0f, 14.0f, 0.0f));
	}

	auto BuildMeterRow = [&](
		FName RowName,
		FName CapName,
		const FLinearColor& CapFill,
		const FString& CapGlyph,
		FName ArcName,
		bool bWithUnderlay,
		UBorder*& OutCap,
		UImage*& OutArc)
	{
		UHorizontalBox* Row = WidgetTree->ConstructWidget<UHorizontalBox>(
			UHorizontalBox::StaticClass(), RowName);
		if (UVerticalBoxSlot* RowSlot = MetersColumn->AddChildToVerticalBox(Row))
		{
			RowSlot->SetPadding(FMargin(0.0f, 0.0f, 0.0f, 4.0f));
		}

		OutCap = MakeDecoCapSlot(WidgetTree, CapName, CapFill);
		OutCap->SetContent(MakeCapGlyph(
			WidgetTree,
			FName(*(CapName.ToString() + TEXT("Glyph"))),
			CapGlyph,
			HudWhite()));
		if (UHorizontalBoxSlot* CapSlot = Row->AddChildToHorizontalBox(OutCap))
		{
			CapSlot->SetVerticalAlignment(VAlign_Center);
			CapSlot->SetPadding(FMargin(0.0f, 0.0f, 4.0f, 0.0f));
			CapSlot->SetSize(FSlateChildSize(ESlateSizeRule::Automatic));
		}

		UOverlay* MeterOverlay = WidgetTree->ConstructWidget<UOverlay>(
			UOverlay::StaticClass(), FName(*(RowName.ToString() + TEXT("Overlay"))));
		if (UHorizontalBoxSlot* OverlaySlot = Row->AddChildToHorizontalBox(MeterOverlay))
		{
			OverlaySlot->SetVerticalAlignment(VAlign_Center);
		}

		if (bWithUnderlay)
		{
			MeterUnderlayImage = MakeMeterImage(WidgetTree, TEXT("MeterUnderlayImage"));
			if (UOverlaySlot* UnderlaySlot = MeterOverlay->AddChildToOverlay(MeterUnderlayImage))
			{
				UnderlaySlot->SetHorizontalAlignment(HAlign_Left);
				UnderlaySlot->SetVerticalAlignment(VAlign_Center);
			}
		}

		OutArc = MakeMeterImage(WidgetTree, ArcName);
		if (UOverlaySlot* ArcSlot = MeterOverlay->AddChildToOverlay(OutArc))
		{
			ArcSlot->SetHorizontalAlignment(HAlign_Left);
			ArcSlot->SetVerticalAlignment(VAlign_Center);
		}
	};

	{
		UBorder* Cap = nullptr;
		UImage* Arc = nullptr;
		BuildMeterRow(
			TEXT("HealthMeterRow"),
			TEXT("HealthCapSlot"),
			FLinearColor(0.55f, 0.08f, 0.08f, 0.95f),
			TEXT("+"),
			TEXT("HealthArcImage"),
			true,
			Cap,
			Arc);
		HealthCapSlot = Cap;
		HealthArcImage = Arc;
	}
	{
		UBorder* Cap = nullptr;
		UImage* Arc = nullptr;
		BuildMeterRow(
			TEXT("EveMeterRow"),
			TEXT("EveCapSlot"),
			FLinearColor(0.12f, 0.28f, 0.55f, 0.95f),
			TEXT("H"),
			TEXT("EveArcImage"),
			false,
			Cap,
			Arc);
		EveCapSlot = Cap;
		EveArcImage = Arc;
	}

	// Hidden verify mirrors (no large on-bar numerals in the default BioShock HUD)
	HealthText = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("HealthText"));
	HealthText->SetVisibility(ESlateVisibility::Collapsed);
	HealthText->SetText(FText::FromString(TEXT("--")));
	MetersColumn->AddChildToVerticalBox(HealthText);

	EveText = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("EveText"));
	EveText->SetVisibility(ESlateVisibility::Collapsed);
	EveText->SetText(FText::FromString(TEXT("EVE --")));
	MetersColumn->AddChildToVerticalBox(EveText);

	ConsumablesText = WidgetTree->ConstructWidget<UTextBlock>(
		UTextBlock::StaticClass(), TEXT("ConsumablesText"));
	ConsumablesText->SetText(FText::GetEmpty());
	ConsumablesText->SetFont(MakeHudFont(12));
	ConsumablesText->SetColorAndOpacity(FSlateColor(FLinearColor(0.85f, 0.9f, 0.85f, 0.85f)));
	ConsumablesText->SetVisibility(ESlateVisibility::Collapsed);
	if (UVerticalBoxSlot* ConsumablesSlot = MetersColumn->AddChildToVerticalBox(ConsumablesText))
	{
		ConsumablesSlot->SetPadding(FMargin(32.0f, 2.0f, 0.0f, 0.0f));
	}

	EnsureHudTextures();

	// Weapon cluster: icon + mag numeral + reserve "+" + ammo type — right of meters, still BL
	AmmoPanel = WidgetTree->ConstructWidget<UBorder>(UBorder::StaticClass(), TEXT("AmmoPanel"));
	AmmoPanel->SetBrushColor(HudTransparent());
	AmmoPanel->SetPadding(FMargin(0.0f));
	if (UHorizontalBoxSlot* AmmoClusterSlot = BottomLeft->AddChildToHorizontalBox(AmmoPanel))
	{
		AmmoClusterSlot->SetVerticalAlignment(VAlign_Bottom);
		AmmoClusterSlot->SetPadding(FMargin(4.0f, 0.0f, 0.0f, 8.0f));
	}

	UHorizontalBox* AmmoRow = WidgetTree->ConstructWidget<UHorizontalBox>(
		UHorizontalBox::StaticClass(), TEXT("AmmoRow"));
	AmmoPanel->SetContent(AmmoRow);

	WeaponIconImage = WidgetTree->ConstructWidget<UImage>(
		UImage::StaticClass(), TEXT("WeaponIconImage"));
	WeaponIconImage->SetBrushSize(FVector2D(WeaponIconSize, WeaponIconSize));
	WeaponIconImage->SetColorAndOpacity(FLinearColor(0.2f, 0.18f, 0.12f, 0.7f));
	WeaponIconImage->SetVisibility(ESlateVisibility::HitTestInvisible);
	if (UHorizontalBoxSlot* WeaponIconSlot = AmmoRow->AddChildToHorizontalBox(WeaponIconImage))
	{
		WeaponIconSlot->SetVerticalAlignment(VAlign_Center);
		WeaponIconSlot->SetPadding(FMargin(0.0f, 0.0f, 8.0f, 0.0f));
	}

	UVerticalBox* AmmoTextCol = WidgetTree->ConstructWidget<UVerticalBox>(
		UVerticalBox::StaticClass(), TEXT("AmmoTextColumn"));
	if (UHorizontalBoxSlot* TextColSlot = AmmoRow->AddChildToHorizontalBox(AmmoTextCol))
	{
		TextColSlot->SetVerticalAlignment(VAlign_Center);
	}

	AmmoWeaponNameText = WidgetTree->ConstructWidget<UTextBlock>(
		UTextBlock::StaticClass(), TEXT("AmmoWeaponNameText"));
	AmmoWeaponNameText->SetText(FText::GetEmpty());
	AmmoWeaponNameText->SetFont(MakeHudFont(12));
	AmmoWeaponNameText->SetColorAndOpacity(FSlateColor(HudWhite()));
	if (UVerticalBoxSlot* NameSlot = AmmoTextCol->AddChildToVerticalBox(AmmoWeaponNameText))
	{
		NameSlot->SetPadding(FMargin(0.0f, 0.0f, 0.0f, 2.0f));
	}

	UHorizontalBox* MagRow = WidgetTree->ConstructWidget<UHorizontalBox>(
		UHorizontalBox::StaticClass(), TEXT("MagRow"));
	AmmoTextCol->AddChildToVerticalBox(MagRow);

	AmmoMagText = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("AmmoMagText"));
	AmmoMagText->SetText(FText::FromString(TEXT("--")));
	AmmoMagText->SetFont(MakeHudFont(36, true));
	AmmoMagText->SetColorAndOpacity(FSlateColor(HudGold()));
	if (UHorizontalBoxSlot* MagSlot = MagRow->AddChildToHorizontalBox(AmmoMagText))
	{
		MagSlot->SetVerticalAlignment(VAlign_Bottom);
	}

	AmmoReserveText = WidgetTree->ConstructWidget<UTextBlock>(
		UTextBlock::StaticClass(), TEXT("AmmoReserveText"));
	AmmoReserveText->SetText(FText::GetEmpty());
	AmmoReserveText->SetFont(MakeHudFont(22, true));
	AmmoReserveText->SetColorAndOpacity(FSlateColor(HudGold()));
	if (UHorizontalBoxSlot* ReserveSlot = MagRow->AddChildToHorizontalBox(AmmoReserveText))
	{
		ReserveSlot->SetVerticalAlignment(VAlign_Bottom);
		ReserveSlot->SetPadding(FMargin(2.0f, 0.0f, 0.0f, 4.0f));
	}

	AmmoTypeText = WidgetTree->ConstructWidget<UTextBlock>(
		UTextBlock::StaticClass(), TEXT("AmmoTypeText"));
	AmmoTypeText->SetText(FText::GetEmpty());
	AmmoTypeText->SetFont(MakeHudFont(11));
	AmmoTypeText->SetColorAndOpacity(FSlateColor(FLinearColor(0.8f, 0.8f, 0.75f, 0.9f)));
	if (UVerticalBoxSlot* TypeSlot = AmmoTextCol->AddChildToVerticalBox(AmmoTypeText))
	{
		TypeSlot->SetPadding(FMargin(0.0f, 2.0f, 0.0f, 0.0f));
	}
}

TSharedRef<SWidget> UShockHudWidget::RebuildWidget()
{
	EnsureWidgetTree();
	return Super::RebuildWidget();
}

void UShockHudWidget::NativeConstruct()
{
	EnsureWidgetTree();
	EnsureHudTextures();
	Super::NativeConstruct();
	EnsureRefreshTimer();
	RefreshDisplay();
}

void UShockHudWidget::NativeDestruct()
{
	if (UWorld* World = GetWorld())
	{
		World->GetTimerManager().ClearTimer(RefreshTimerHandle);
	}
	Super::NativeDestruct();
}

void UShockHudWidget::EnsureRefreshTimer()
{
	UWorld* World = GetWorld();
	if (!World || RefreshTimerHandle.IsValid())
	{
		return;
	}
	World->GetTimerManager().SetTimer(
		RefreshTimerHandle,
		FTimerDelegate::CreateUObject(this, &UShockHudWidget::RefreshDisplay),
		RefreshIntervalSeconds,
		true);
}

void UShockHudWidget::RefreshDisplayNow()
{
	RefreshDisplay();
}

AShockPlayer* UShockHudWidget::ResolvePlayer() const
{
	if (DisplayPlayerOverride.IsValid())
	{
		return DisplayPlayerOverride.Get();
	}
	if (APawn* Pawn = GetOwningPlayerPawn())
	{
		return Cast<AShockPlayer>(Pawn);
	}
	if (APlayerController* PC = GetOwningPlayer())
	{
		return Cast<AShockPlayer>(PC->GetPawn());
	}
	return nullptr;
}

AShockWeapon* UShockHudWidget::ResolveEquippedWeapon(AShockPlayer* Player) const
{
	return Player ? Player->GetEquippedWeapon() : nullptr;
}

void UShockHudWidget::ApplyDamageFlashVisual(bool bFlashing)
{
	if (HealthText)
	{
		HealthText->SetColorAndOpacity(FSlateColor(bFlashing ? HudRed() : HudWhite()));
	}
	if (HealthArcImage)
	{
		const float Alpha = HealthArcImage->GetColorAndOpacity().A;
		HealthArcImage->SetColorAndOpacity(
			bFlashing ? FLinearColor(1.0f, 0.35f, 0.3f, Alpha) : FLinearColor(1.0f, 1.0f, 1.0f, Alpha));
	}
	if (HealthCapSlot)
	{
		HealthCapSlot->SetBrushColor(
			bFlashing ? HudRed() : FLinearColor(0.55f, 0.08f, 0.08f, 0.95f));
	}
}

void UShockHudWidget::SetMeterImageOpacity(UImage* Image, float Percent) const
{
	if (!Image)
	{
		return;
	}
	// FrozenHealth_DangerBar's 20 in-SWF frames animate via ColorTransform; frame-0 export is the
	// full arc. Map 0-100% onto opacity as a first-pass stand-in until multi-frame export exists.
	const float Clamped = FMath::Clamp(Percent, 0.0f, 1.0f);
	const float Alpha = FMath::Lerp(0.2f, 1.0f, Clamped);
	const FLinearColor Current = Image->GetColorAndOpacity();
	Image->SetColorAndOpacity(FLinearColor(Current.R, Current.G, Current.B, Alpha));
}

void UShockHudWidget::RefreshDisplay()
{
	EnsureWidgetTree();
	EnsureHudTextures();

	UWorld* World = GetWorld();
	const double Now = World ? static_cast<double>(World->GetTimeSeconds()) : 0.0;
	if (DamageFlashEndTime >= 0.0 && Now >= DamageFlashEndTime)
	{
		DamageFlashEndTime = -1.0;
		ApplyDamageFlashVisual(false);
	}

	AShockPlayer* Player = ResolvePlayer();
	const float Health = Player ? Player->GetCurrentHealth() : 0.0f;
	float MaxHealth = Player ? Player->AuthoredMaxHealth : 0.0f;
	if (MaxHealth <= 0.0f && Player)
	{
		MaxHealth = Player->AuthoredHealth;
	}
	if (MaxHealth <= 0.0f)
	{
		MaxHealth = FMath::Max(Health, 1.0f);
	}

	if (LastObservedHealth >= 0.0f && Health < LastObservedHealth - KINDA_SMALL_NUMBER)
	{
		DamageFlashEndTime = Now + static_cast<double>(DamageFlashSeconds);
		ApplyDamageFlashVisual(true);
	}
	else if (DamageFlashEndTime < 0.0)
	{
		ApplyDamageFlashVisual(false);
	}
	LastObservedHealth = Health;

	CachedHealthText = FString::FromInt(FMath::RoundToInt(Health));
	if (HealthText)
	{
		HealthText->SetText(FText::FromString(CachedHealthText));
	}
	SetMeterImageOpacity(HealthArcImage, Health / MaxHealth);

	const float Eve = Player ? Player->GetCurrentEve() : 0.0f;
	float MaxEve = Player ? Player->GetMaxEve() : 0.0f;
	if (MaxEve <= 0.0f)
	{
		MaxEve = FMath::Max(Eve, 1.0f);
	}
	CachedEveText = FString::Printf(TEXT("EVE %d"), FMath::RoundToInt(Eve));
	if (EveText)
	{
		EveText->SetText(FText::FromString(CachedEveText));
	}
	SetMeterImageOpacity(EveArcImage, Eve / MaxEve);

	if (ObjectiveText)
	{
		FString Objective;
		if (Player)
		{
			Objective = Player->GetMapHUDRegion();
			if (Objective.IsEmpty() && !Player->GetActiveQuest().IsNone())
			{
				Objective = Player->GetActiveQuest().ToString();
			}
		}
		ObjectiveText->SetText(FText::FromString(Objective));
		ObjectiveText->SetVisibility(
			Objective.IsEmpty() ? ESlateVisibility::Collapsed : ESlateVisibility::HitTestInvisible);
	}

	if (ConsumablesText)
	{
		int32 KitCount = 0;
		int32 HypoCount = 0;
		int32 Money = 0;
		if (Player)
		{
			KitCount = Player->GetInventoryStack(FName(TEXT("FirstAidKit")));
			HypoCount = Player->GetInventoryStack(FName(TEXT("EveHypo")));
			Money = Player->GetMoney();
		}
		CachedConsumablesText = FString::Printf(
			TEXT("Kit %d  Hypo %d  $%d"),
			KitCount,
			HypoCount,
			Money);
		ConsumablesText->SetText(FText::FromString(CachedConsumablesText));
		ConsumablesText->SetVisibility(
			(KitCount > 0 || HypoCount > 0 || Money > 0)
				? ESlateVisibility::HitTestInvisible
				: ESlateVisibility::Collapsed);
	}

	if (PlasmidText || EveCostText)
	{
		FString PlasmidLabel;
		int32 EveCostRounded = 0;
		bool bHasPlasmid = false;
		if (Player)
		{
			if (const UShockPlasmid* ActivePlasmid = Player->GetActivePlasmid())
			{
				bHasPlasmid = true;
				PlasmidLabel = ActivePlasmid->PlasmidName.ToString();
				EveCostRounded = FMath::RoundToInt(ActivePlasmid->GetCastEveCost(Player));
			}
		}
		CachedPlasmidText = PlasmidLabel;
		if (PlasmidText)
		{
			PlasmidText->SetText(FText::FromString(CachedPlasmidText));
			PlasmidText->SetVisibility(
				PlasmidLabel.IsEmpty() ? ESlateVisibility::Collapsed : ESlateVisibility::HitTestInvisible);
		}
		if (EveCostText)
		{
			if (bHasPlasmid)
			{
				EveCostText->SetText(FText::FromString(FString::FromInt(EveCostRounded)));
				EveCostText->SetVisibility(ESlateVisibility::HitTestInvisible);
			}
			else
			{
				EveCostText->SetText(FText::GetEmpty());
				EveCostText->SetVisibility(ESlateVisibility::Collapsed);
			}
		}
		if (PlasmidRing)
		{
			PlasmidRing->SetVisibility(ESlateVisibility::HitTestInvisible);
		}
	}

	AShockWeapon* Weapon = ResolveEquippedWeapon(Player);
	const bool bShowAmmo = Weapon && Weapon->bEnforceAmmo;
	bAmmoPanelVisible = bShowAmmo;
	if (AmmoPanel)
	{
		AmmoPanel->SetVisibility(bShowAmmo ? ESlateVisibility::HitTestInvisible : ESlateVisibility::Collapsed);
	}

	if (!bShowAmmo)
	{
		CachedAmmoMagText = TEXT("");
		CachedWeaponNameText = TEXT("");
		CachedAmmoReserveText = TEXT("");
		if (AmmoWeaponNameText)
		{
			AmmoWeaponNameText->SetText(FText::GetEmpty());
		}
		if (AmmoMagText)
		{
			AmmoMagText->SetText(FText::GetEmpty());
		}
		if (AmmoReserveText)
		{
			AmmoReserveText->SetText(FText::GetEmpty());
		}
		if (AmmoTypeText)
		{
			AmmoTypeText->SetText(FText::GetEmpty());
		}
		return;
	}

	const int32 Mag = Weapon->GetRoundsInMagazine();
	const int32 Reserve = Weapon->GetReserveAmmo();
	CachedWeaponNameText = Weapon->GetWeaponDefName().IsNone() ? TEXT("") : Weapon->GetWeaponDefName().ToString();
	CachedAmmoMagText = FString::FromInt(Mag);
	// BioShock PC: magazine numeral with "+" when reserve ammo remains.
	CachedAmmoReserveText = Reserve > 0 ? TEXT("+") : TEXT("");
	if (AmmoWeaponNameText)
	{
		AmmoWeaponNameText->SetText(FText::FromString(CachedWeaponNameText));
	}
	if (AmmoMagText)
	{
		AmmoMagText->SetText(FText::FromString(CachedAmmoMagText));
	}
	if (AmmoReserveText)
	{
		AmmoReserveText->SetText(FText::FromString(CachedAmmoReserveText));
	}
	if (AmmoTypeText)
	{
		const FName AmmoTypeName = Weapon->GetActiveAmmoTypeName();
		AmmoTypeText->SetText(
			AmmoTypeName.IsNone() ? FText::GetEmpty() : FText::FromName(AmmoTypeName));
	}
}

FString UShockHudWidget::GetDisplayedHealthText() const
{
	return CachedHealthText;
}

FString UShockHudWidget::GetDisplayedAmmoMagText() const
{
	return CachedAmmoMagText;
}

FString UShockHudWidget::GetDisplayedWeaponNameText() const
{
	return CachedWeaponNameText;
}

FString UShockHudWidget::GetDisplayedAmmoReserveText() const
{
	return CachedAmmoReserveText;
}

FString UShockHudWidget::GetDisplayedEveText() const
{
	return CachedEveText;
}

FString UShockHudWidget::GetDisplayedConsumablesText() const
{
	return CachedConsumablesText;
}

bool UShockHudWidget::HasHealthArcTexture() const
{
	return HealthArcTexture != nullptr && BrushHasTexture(HealthArcImage);
}

bool UShockHudWidget::HasEveArcTexture() const
{
	return EveArcTexture != nullptr && BrushHasTexture(EveArcImage);
}

bool UShockHudWidget::RunHeadlessHudVerify(UObject* WorldContextObject)
{
	LastHudVerifyError.Empty();

	UWorld* World = GEngine
		? GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::ReturnNull)
		: nullptr;
	if (!World)
	{
		LastHudVerifyError = TEXT("no world");
		return false;
	}

	const FVector SpawnLoc(120.0f, 0.0f, 100.0f);
	FActorSpawnParameters Params;
	Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;

	AShockPlayer* Player = World->SpawnActor<AShockPlayer>(
		AShockPlayer::StaticClass(), SpawnLoc, FRotator::ZeroRotator, Params);
	AShockWeapon* Weapon = World->SpawnActor<AShockWeapon>(
		AShockWeapon::StaticClass(), SpawnLoc, FRotator::ZeroRotator, Params);
	if (!Player || !Weapon)
	{
		LastHudVerifyError = TEXT("spawn player/weapon failed");
		if (Player)
		{
			Player->Destroy();
		}
		if (Weapon)
		{
			Weapon->Destroy();
		}
		return false;
	}

	Player->EnsureHealthInitialized();
	Weapon->ConfigureHitscan(10.0f, 5000.0f);
	Weapon->ConfigureAmmo(50, 150, 10.0f, 2.5f);
	Weapon->InitializeAmmoFullMag(150);
	Player->EquipWeapon(Weapon);

	UShockHudWidget* Hud = CreateWidget<UShockHudWidget>(World, UShockHudWidget::StaticClass());
	if (!Hud)
	{
		LastHudVerifyError = TEXT("CreateWidget failed");
		Player->Destroy();
		Weapon->Destroy();
		return false;
	}

	Hud->BindDisplayPlayer(Player);
	Hud->RefreshDisplayNow();

	const int32 ExpectedHealth = FMath::RoundToInt(Player->GetCurrentHealth());
	const int32 ExpectedMag = Weapon->GetRoundsInMagazine();
	const int32 ExpectedReserve = Weapon->GetReserveAmmo();

	if (Hud->GetDisplayedHealthText() != FString::FromInt(ExpectedHealth))
	{
		LastHudVerifyError = FString::Printf(
			TEXT("health text %s != %d"),
			*Hud->GetDisplayedHealthText(),
			ExpectedHealth);
		Hud->RemoveFromParent();
		Player->Destroy();
		Weapon->Destroy();
		return false;
	}
	if (!Hud->HasHealthArcTexture())
	{
		LastHudVerifyError = TEXT(
			"health arc UImage has null texture — run tools/ue5/export_hud_ui.py then "
			"import_hud_ui.py into /Game/BioShockUI/HUD");
		Hud->RemoveFromParent();
		Player->Destroy();
		Weapon->Destroy();
		return false;
	}
	if (!Hud->HasEveArcTexture())
	{
		LastHudVerifyError = TEXT(
			"eve arc UImage has null texture — run tools/ue5/export_hud_ui.py then "
			"import_hud_ui.py into /Game/BioShockUI/HUD");
		Hud->RemoveFromParent();
		Player->Destroy();
		Weapon->Destroy();
		return false;
	}
	if (!Hud->IsAmmoPanelVisible())
	{
		LastHudVerifyError = TEXT("ammo panel hidden with enforce ammo weapon");
		Hud->RemoveFromParent();
		Player->Destroy();
		Weapon->Destroy();
		return false;
	}
	if (Hud->GetDisplayedAmmoMagText() != FString::FromInt(ExpectedMag))
	{
		LastHudVerifyError = FString::Printf(
			TEXT("mag text %s != %d"),
			*Hud->GetDisplayedAmmoMagText(),
			ExpectedMag);
		Hud->RemoveFromParent();
		Player->Destroy();
		Weapon->Destroy();
		return false;
	}
	const FString ExpectedReserveText = ExpectedReserve > 0 ? TEXT("+") : TEXT("");
	if (Hud->GetDisplayedAmmoReserveText() != ExpectedReserveText)
	{
		LastHudVerifyError = FString::Printf(
			TEXT("reserve text %s != %s"),
			*Hud->GetDisplayedAmmoReserveText(),
			*ExpectedReserveText);
		Hud->RemoveFromParent();
		Player->Destroy();
		Weapon->Destroy();
		return false;
	}

	Hud->AddToViewport(0);
	if (World->IsGameWorld() && !Hud->IsInViewport())
	{
		LastHudVerifyError = TEXT("HUD not in viewport after AddToViewport");
		Hud->RemoveFromParent();
		Player->Destroy();
		Weapon->Destroy();
		return false;
	}

	const float DamageAmount = 25.0f;
	UShockDamageLibrary::ApplyDamage(Player, DamageAmount, nullptr, FName(TEXT("HudVerify")));
	Hud->RefreshDisplayNow();

	const int32 ExpectedHealthAfter = FMath::RoundToInt(Player->GetCurrentHealth());
	if (Hud->GetDisplayedHealthText() != FString::FromInt(ExpectedHealthAfter))
	{
		LastHudVerifyError = FString::Printf(
			TEXT("health after damage %s != %d"),
			*Hud->GetDisplayedHealthText(),
			ExpectedHealthAfter);
		Hud->RemoveFromParent();
		Player->Destroy();
		Weapon->Destroy();
		return false;
	}
	if (ExpectedHealthAfter >= ExpectedHealth)
	{
		LastHudVerifyError = TEXT("damage did not reduce health");
		Hud->RemoveFromParent();
		Player->Destroy();
		Weapon->Destroy();
		return false;
	}

	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_HUD_OK health=%d mag=%d reserve=%d health_after=%d viewport=%d "
			 "health_tex=%d eve_tex=%d layout=bioshock_bl"),
		ExpectedHealth,
		ExpectedMag,
		ExpectedReserve,
		ExpectedHealthAfter,
		Hud->IsInViewport() ? 1 : 0,
		Hud->HasHealthArcTexture() ? 1 : 0,
		Hud->HasEveArcTexture() ? 1 : 0);

	Hud->RemoveFromParent();
	Player->Destroy();
	Weapon->Destroy();

	AShockPlayer* NoAmmoPlayer = World->SpawnActor<AShockPlayer>(
		AShockPlayer::StaticClass(), SpawnLoc + FVector(300.0f, 0.0f, 0.0f), FRotator::ZeroRotator, Params);
	AShockWeapon* NoAmmoWeapon = World->SpawnActor<AShockWeapon>(
		AShockWeapon::StaticClass(), SpawnLoc + FVector(300.0f, 0.0f, 0.0f), FRotator::ZeroRotator, Params);
	if (!NoAmmoPlayer || !NoAmmoWeapon)
	{
		LastHudVerifyError = TEXT("no-ammo spawn failed");
		if (NoAmmoPlayer)
		{
			NoAmmoPlayer->Destroy();
		}
		if (NoAmmoWeapon)
		{
			NoAmmoWeapon->Destroy();
		}
		return false;
	}
	NoAmmoPlayer->EnsureHealthInitialized();
	NoAmmoWeapon->ConfigureHitscan(10.0f, 5000.0f);
	NoAmmoWeapon->SetEnforceAmmo(false);
	NoAmmoPlayer->EquipWeapon(NoAmmoWeapon);

	UShockHudWidget* NoAmmoHud = CreateWidget<UShockHudWidget>(World, UShockHudWidget::StaticClass());
	if (!NoAmmoHud)
	{
		LastHudVerifyError = TEXT("no-ammo CreateWidget failed");
		NoAmmoPlayer->Destroy();
		NoAmmoWeapon->Destroy();
		return false;
	}
	NoAmmoHud->BindDisplayPlayer(NoAmmoPlayer);
	NoAmmoHud->RefreshDisplayNow();
	if (NoAmmoHud->IsAmmoPanelVisible())
	{
		LastHudVerifyError = TEXT("ammo panel visible when bEnforceAmmo false");
		NoAmmoPlayer->Destroy();
		NoAmmoWeapon->Destroy();
		return false;
	}
	NoAmmoPlayer->Destroy();
	NoAmmoWeapon->Destroy();
	return true;
}
