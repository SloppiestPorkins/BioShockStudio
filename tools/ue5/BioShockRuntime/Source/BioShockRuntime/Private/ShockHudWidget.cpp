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
#include "Components/ProgressBar.h"
#include "Components/SizeBox.h"
#include "Components/TextBlock.h"
#include "Components/VerticalBox.h"
#include "Components/VerticalBoxSlot.h"
#include "Engine/Engine.h"
#include "Engine/Texture2D.h"
#include "Engine/World.h"
#include "GameFramework/PlayerController.h"
#include "Styling/CoreStyle.h"
#include "TimerManager.h"

FString UShockHudWidget::LastHudVerifyError;

namespace
{
constexpr float RefreshIntervalSeconds = 0.1f;
constexpr float DamageFlashSeconds = 0.35f;

// ~85% of the 661x137 source crop — reads clearly at 1280x720 without dominating.
constexpr float MeterDisplayWidth = 560.0f;
constexpr float MeterDisplayHeight = 116.0f;
// Source fill insets (32,28,32,28) on 661x137 → scaled to display.
constexpr float FillInsetLeft = 32.0f * MeterDisplayWidth / 661.0f;
constexpr float FillInsetTop = 28.0f * MeterDisplayHeight / 137.0f;
constexpr float FillInsetRight = 32.0f * MeterDisplayWidth / 661.0f;
constexpr float FillInsetBottom = 28.0f * MeterDisplayHeight / 137.0f;
// 9-slice margins on source crop (68,22,68,22) as normalized FMargin L,T,R,B.
constexpr float SliceLeft = 68.0f / 661.0f;
constexpr float SliceTop = 22.0f / 137.0f;
constexpr float SliceRight = 68.0f / 661.0f;
constexpr float SliceBottom = 22.0f / 137.0f;

constexpr float CapIconSize = 36.0f;
constexpr float CountDigitWidth = 22.0f;
constexpr float CountDigitHeight = 44.0f;

constexpr float MagDigitWidth = 28.0f;
constexpr float MagDigitHeight = 56.0f;
constexpr float ReserveDigitWidth = 16.0f;
constexpr float ReserveDigitHeight = 32.0f;
constexpr int32 MaxMagDigits = 3;
constexpr int32 MaxReserveDigits = 4;

const TCHAR* MeterFrameTexturePath = TEXT("/Game/BioShockUI/HUD/T_Hud_MeterFrame.T_Hud_MeterFrame");
const TCHAR* FillMaskTexturePath = TEXT("/Game/BioShockUI/HUD/T_Hud_FillMask.T_Hud_FillMask");
const TCHAR* FillWhiteTexturePath = TEXT("/Game/BioShockUI/HUD/T_Hud_FillWhite.T_Hud_FillWhite");
const TCHAR* BrassRingTexturePath = TEXT("/Game/BioShockUI/HUD/T_Hud_BrassRing.T_Hud_BrassRing");
const TCHAR* VignetteTexturePath = TEXT("/Game/BioShockUI/HUD/T_Hud_Vignette.T_Hud_Vignette");
const TCHAR* CrossIconTexturePath = TEXT("/Game/BioShockUI/HUD/T_Hud_Icon_Cross.T_Hud_Icon_Cross");
const TCHAR* HypoIconTexturePath = TEXT("/Game/BioShockUI/HUD/T_Hud_Icon_Hypo.T_Hud_Icon_Hypo");

FString DigitTexturePath(int32 Digit)
{
	return FString::Printf(
		TEXT("/Game/BioShockUI/HUD/T_Hud_Digit_%d.T_Hud_Digit_%d"), Digit, Digit);
}

FLinearColor HudGold() { return FLinearColor(0.92f, 0.78f, 0.35f, 1.0f); }
FLinearColor HudWhite() { return FLinearColor(0.95f, 0.95f, 0.95f, 1.0f); }
FLinearColor HudHealthFill() { return FLinearColor(0.85f, 0.08f, 0.06f, 0.92f); }
FLinearColor HudEveFill() { return FLinearColor(0.15f, 0.45f, 0.95f, 0.92f); }
FLinearColor HudDamageEdge() { return FLinearColor(0.75f, 0.02f, 0.02f, 0.55f); }

FSlateFontInfo MakeHudFont(int32 Size, bool bBold = false)
{
	return FCoreStyle::GetDefaultFontStyle(bBold ? TEXT("Bold") : TEXT("Regular"), Size);
}

bool BrushHasTexture(const UImage* Image)
{
	if (!Image)
	{
		return false;
	}
	return Image->GetBrush().GetResourceObject() != nullptr;
}

void ApplyMeterFrameBrush(UImage* Image, UTexture2D* Texture)
{
	if (!Image || !Texture)
	{
		return;
	}
	FSlateBrush Brush;
	Brush.SetResourceObject(Texture);
	Brush.ImageSize = FVector2D(MeterDisplayWidth, MeterDisplayHeight);
	// Image (not 9-slice Box): FillMask and the cavity punch share the same source pixels —
	// Box margins would stretch the punched hole out of register with the fill silhouette.
	Brush.DrawAs = ESlateBrushDrawType::Image;
	Brush.Tiling = ESlateBrushTileType::NoTile;
	Image->SetBrush(Brush);
	Image->SetDesiredSizeOverride(FVector2D(MeterDisplayWidth, MeterDisplayHeight));
}

void ApplyFillBarStyle(UProgressBar* Bar, UTexture2D* Mask, const FLinearColor& Tint)
{
	if (!Bar || !Mask)
	{
		return;
	}
	FProgressBarStyle Style = Bar->GetWidgetStyle();
	FSlateBrush Fill;
	Fill.SetResourceObject(Mask);
	Fill.ImageSize = FVector2D(MeterDisplayWidth, MeterDisplayHeight);
	Fill.DrawAs = ESlateBrushDrawType::Image;
	Fill.Tiling = ESlateBrushTileType::NoTile;
	Fill.TintColor = FSlateColor(Tint);
	Style.SetFillImage(Fill);
	FSlateBrush Bg;
	Bg.DrawAs = ESlateBrushDrawType::NoDrawType;
	Style.SetBackgroundImage(Bg);
	Style.SetEnableFillAnimation(false);
	Bar->SetWidgetStyle(Style);
	Bar->SetFillColorAndOpacity(Tint);
}

UCanvasPanelSlot* AnchorCorner(
	UCanvasPanel* Canvas,
	UWidget* Child,
	float AnchorX,
	float AnchorY,
	float AlignX,
	float AlignY,
	const FVector2D& Position,
	bool bAutoSize = true)
{
	UCanvasPanelSlot* Slot = Canvas->AddChildToCanvas(Child);
	Slot->SetAnchors(FAnchors(AnchorX, AnchorY, AnchorX, AnchorY));
	Slot->SetAlignment(FVector2D(AlignX, AlignY));
	Slot->SetAutoSize(bAutoSize);
	Slot->SetPosition(Position);
	return Slot;
}

UImage* MakeImage(UWidgetTree* Tree, FName Name, const FVector2D& Size)
{
	UImage* Image = Tree->ConstructWidget<UImage>(UImage::StaticClass(), Name);
	Image->SetBrushSize(Size);
	Image->SetVisibility(ESlateVisibility::HitTestInvisible);
	return Image;
}

UBorder* MakeEdgeFlash(UWidgetTree* Tree, FName Name)
{
	UBorder* Border = Tree->ConstructWidget<UBorder>(UBorder::StaticClass(), Name);
	Border->SetBrushColor(FLinearColor(0.0f, 0.0f, 0.0f, 0.0f));
	Border->SetVisibility(ESlateVisibility::HitTestInvisible);
	return Border;
}

/**
 * Meter stack: FillMask ProgressBar UNDER the punched frame, then cap icon + count digit
 * on the left bulb. ProgressBar clips the stadium mask to percent without squashing.
 */
UOverlay* MakeMeterStack(
	UWidgetTree* Tree,
	FName OverlayName,
	UImage*& OutFrame,
	FName FrameName,
	UProgressBar*& OutFillBar,
	FName FillBarName,
	UImage*& OutCapIcon,
	FName CapIconName,
	UImage*& OutCountDigit,
	FName CountDigitName)
{
	UOverlay* Overlay = Tree->ConstructWidget<UOverlay>(UOverlay::StaticClass(), OverlayName);
	Overlay->SetClipping(EWidgetClipping::ClipToBounds);

	OutFillBar = Tree->ConstructWidget<UProgressBar>(UProgressBar::StaticClass(), FillBarName);
	OutFillBar->SetPercent(1.0f);
	OutFillBar->SetVisibility(ESlateVisibility::HitTestInvisible);
	if (UOverlaySlot* FillSlot = Overlay->AddChildToOverlay(OutFillBar))
	{
		FillSlot->SetHorizontalAlignment(HAlign_Fill);
		FillSlot->SetVerticalAlignment(VAlign_Fill);
	}

	OutFrame = MakeImage(Tree, FrameName, FVector2D(MeterDisplayWidth, MeterDisplayHeight));
	if (UOverlaySlot* FrameSlot = Overlay->AddChildToOverlay(OutFrame))
	{
		FrameSlot->SetHorizontalAlignment(HAlign_Fill);
		FrameSlot->SetVerticalAlignment(VAlign_Fill);
	}

	UHorizontalBox* CapRow = Tree->ConstructWidget<UHorizontalBox>(
		UHorizontalBox::StaticClass(), *FString::Printf(TEXT("%s_CapRow"), *OverlayName.ToString()));
	OutCapIcon = MakeImage(Tree, CapIconName, FVector2D(CapIconSize, CapIconSize));
	if (UHorizontalBoxSlot* CapSlot = CapRow->AddChildToHorizontalBox(OutCapIcon))
	{
		CapSlot->SetVerticalAlignment(VAlign_Center);
		CapSlot->SetPadding(FMargin(0.0f, 0.0f, 4.0f, 0.0f));
	}
	OutCountDigit = MakeImage(Tree, CountDigitName, FVector2D(CountDigitWidth, CountDigitHeight));
	if (UHorizontalBoxSlot* DigitSlot = CapRow->AddChildToHorizontalBox(OutCountDigit))
	{
		DigitSlot->SetVerticalAlignment(VAlign_Center);
	}
	if (UOverlaySlot* CapRowSlot = Overlay->AddChildToOverlay(CapRow))
	{
		CapRowSlot->SetPadding(FMargin(22.0f, 0.0f, 0.0f, 0.0f));
		CapRowSlot->SetHorizontalAlignment(HAlign_Left);
		CapRowSlot->SetVerticalAlignment(VAlign_Center);
	}
	return Overlay;
}
} // namespace

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
	if (!MeterFrameTexture)
	{
		MeterFrameTexture = LoadObject<UTexture2D>(nullptr, MeterFrameTexturePath);
	}
	if (!FillMaskTexture)
	{
		FillMaskTexture = LoadObject<UTexture2D>(nullptr, FillMaskTexturePath);
	}
	if (!BrassRingTexture)
	{
		BrassRingTexture = LoadObject<UTexture2D>(nullptr, BrassRingTexturePath);
	}
	if (!VignetteTexture)
	{
		VignetteTexture = LoadObject<UTexture2D>(nullptr, VignetteTexturePath);
	}
	if (!CrossIconTexture)
	{
		CrossIconTexture = LoadObject<UTexture2D>(nullptr, CrossIconTexturePath);
	}
	if (!HypoIconTexture)
	{
		HypoIconTexture = LoadObject<UTexture2D>(nullptr, HypoIconTexturePath);
	}
	for (int32 Digit = 0; Digit < 10; ++Digit)
	{
		if (!DigitTextures[Digit])
		{
			DigitTextures[Digit] = LoadObject<UTexture2D>(nullptr, *DigitTexturePath(Digit));
		}
	}

	ApplyMeterFrameBrush(HealthMeterFrame, MeterFrameTexture);
	ApplyMeterFrameBrush(EveMeterFrame, MeterFrameTexture);

	if (HealthFillBar && FillMaskTexture)
	{
		ApplyFillBarStyle(HealthFillBar, FillMaskTexture, HudHealthFill());
	}
	if (EveFillBar && FillMaskTexture)
	{
		ApplyFillBarStyle(EveFillBar, FillMaskTexture, HudEveFill());
	}
	if (HealthCapIcon && CrossIconTexture)
	{
		HealthCapIcon->SetBrushFromTexture(CrossIconTexture, true);
		HealthCapIcon->SetBrushSize(FVector2D(CapIconSize, CapIconSize));
	}
	if (EveCapIcon && HypoIconTexture)
	{
		EveCapIcon->SetBrushFromTexture(HypoIconTexture, true);
		EveCapIcon->SetBrushSize(FVector2D(CapIconSize, CapIconSize));
	}
	if (PlasmidRingImage && BrassRingTexture)
	{
		PlasmidRingImage->SetBrushFromTexture(BrassRingTexture, true);
		PlasmidRingImage->SetBrushSize(FVector2D(72.0f, 72.0f));
	}
	if (WeaponRingImage && BrassRingTexture)
	{
		WeaponRingImage->SetBrushFromTexture(BrassRingTexture, true);
		WeaponRingImage->SetBrushSize(FVector2D(72.0f, 72.0f));
	}
	if (VignetteImage && VignetteTexture)
	{
		VignetteImage->SetBrushFromTexture(VignetteTexture, true);
	}
}

void UShockHudWidget::EnsureWidgetTree()
{
	if (!WidgetTree || HealthMeterFrame)
	{
		return;
	}

	UCanvasPanel* Canvas = WidgetTree->ConstructWidget<UCanvasPanel>(
		UCanvasPanel::StaticClass(), TEXT("HudCanvas"));
	WidgetTree->RootWidget = Canvas;

	// Bottom vignette (full width).
	VignetteImage = MakeImage(WidgetTree, TEXT("VignetteImage"), FVector2D(32.0f, 32.0f));
	VignetteImage->SetColorAndOpacity(FLinearColor(1.0f, 1.0f, 1.0f, 0.85f));
	if (UCanvasPanelSlot* VigSlot = Canvas->AddChildToCanvas(VignetteImage))
	{
		VigSlot->SetAnchors(FAnchors(0.0f, 1.0f, 1.0f, 1.0f));
		VigSlot->SetAlignment(FVector2D(0.5f, 1.0f));
		VigSlot->SetOffsets(FMargin(0.0f, -128.0f, 0.0f, 0.0f));
	}

	// Screen-edge damage flash (repurposed DamageFlashEndTime).
	DamageFlashLeft = MakeEdgeFlash(WidgetTree, TEXT("DamageFlashLeft"));
	if (UCanvasPanelSlot* L = Canvas->AddChildToCanvas(DamageFlashLeft))
	{
		L->SetAnchors(FAnchors(0.0f, 0.0f, 0.0f, 1.0f));
		L->SetOffsets(FMargin(0.0f, 0.0f, 48.0f, 0.0f));
	}
	DamageFlashRight = MakeEdgeFlash(WidgetTree, TEXT("DamageFlashRight"));
	if (UCanvasPanelSlot* R = Canvas->AddChildToCanvas(DamageFlashRight))
	{
		R->SetAnchors(FAnchors(1.0f, 0.0f, 1.0f, 1.0f));
		R->SetAlignment(FVector2D(1.0f, 0.0f));
		R->SetOffsets(FMargin(-48.0f, 0.0f, 0.0f, 0.0f));
	}
	DamageFlashTop = MakeEdgeFlash(WidgetTree, TEXT("DamageFlashTop"));
	if (UCanvasPanelSlot* T = Canvas->AddChildToCanvas(DamageFlashTop))
	{
		T->SetAnchors(FAnchors(0.0f, 0.0f, 1.0f, 0.0f));
		T->SetOffsets(FMargin(0.0f, 0.0f, 0.0f, 36.0f));
	}
	DamageFlashBottom = MakeEdgeFlash(WidgetTree, TEXT("DamageFlashBottom"));
	if (UCanvasPanelSlot* B = Canvas->AddChildToCanvas(DamageFlashBottom))
	{
		B->SetAnchors(FAnchors(0.0f, 1.0f, 1.0f, 1.0f));
		B->SetAlignment(FVector2D(0.0f, 1.0f));
		B->SetOffsets(FMargin(0.0f, -36.0f, 0.0f, 0.0f));
	}

	// Upper-left: health over EVE (cap icon + digit live inside each meter overlay).
	UVerticalBox* MeterCluster = WidgetTree->ConstructWidget<UVerticalBox>(
		UVerticalBox::StaticClass(), TEXT("MeterCluster"));

	UImage* HealthFramePtr = nullptr;
	UProgressBar* HealthFillBarPtr = nullptr;
	UImage* HealthCapPtr = nullptr;
	UImage* KitDigitPtr = nullptr;
	UOverlay* HealthMeter = MakeMeterStack(
		WidgetTree,
		TEXT("HealthMeterOverlay"),
		HealthFramePtr,
		TEXT("HealthMeterFrame"),
		HealthFillBarPtr,
		TEXT("HealthFillBar"),
		HealthCapPtr,
		TEXT("HealthCapIcon"),
		KitDigitPtr,
		TEXT("KitCountDigit"));
	HealthMeterFrame = HealthFramePtr;
	HealthFillBar = HealthFillBarPtr;
	HealthCapIcon = HealthCapPtr;
	KitCountDigit = KitDigitPtr;
	USizeBox* HealthSize = WidgetTree->ConstructWidget<USizeBox>(
		USizeBox::StaticClass(), TEXT("HealthMeterSize"));
	HealthSize->SetWidthOverride(MeterDisplayWidth);
	HealthSize->SetHeightOverride(MeterDisplayHeight);
	HealthSize->AddChild(HealthMeter);
	if (UVerticalBoxSlot* HealthRowSlot = MeterCluster->AddChildToVerticalBox(HealthSize))
	{
		HealthRowSlot->SetPadding(FMargin(0.0f, 0.0f, 0.0f, 8.0f));
	}

	UImage* EveFramePtr = nullptr;
	UProgressBar* EveFillBarPtr = nullptr;
	UImage* EveCapPtr = nullptr;
	UImage* HypoDigitPtr = nullptr;
	UOverlay* EveMeter = MakeMeterStack(
		WidgetTree,
		TEXT("EveMeterOverlay"),
		EveFramePtr,
		TEXT("EveMeterFrame"),
		EveFillBarPtr,
		TEXT("EveFillBar"),
		EveCapPtr,
		TEXT("EveCapIcon"),
		HypoDigitPtr,
		TEXT("HypoCountDigit"));
	EveMeterFrame = EveFramePtr;
	EveFillBar = EveFillBarPtr;
	EveCapIcon = EveCapPtr;
	HypoCountDigit = HypoDigitPtr;
	USizeBox* EveSize = WidgetTree->ConstructWidget<USizeBox>(
		USizeBox::StaticClass(), TEXT("EveMeterSize"));
	EveSize->SetWidthOverride(MeterDisplayWidth);
	EveSize->SetHeightOverride(MeterDisplayHeight);
	EveSize->AddChild(EveMeter);
	MeterCluster->AddChildToVerticalBox(EveSize);

	AnchorCorner(Canvas, MeterCluster, 0.0f, 0.0f, 0.0f, 0.0f, FVector2D(28.0f, 28.0f));

	// Top-center toasts / prompts.
	ToastText = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("ToastText"));
	ToastText->SetText(FText::GetEmpty());
	ToastText->SetFont(MakeHudFont(20, true));
	ToastText->SetColorAndOpacity(FSlateColor(HudGold()));
	ToastText->SetJustification(ETextJustify::Center);
	ToastText->SetVisibility(ESlateVisibility::Collapsed);
	AnchorCorner(Canvas, ToastText, 0.5f, 0.0f, 0.5f, 0.0f, FVector2D(0.0f, 36.0f));

	// Center crosshair (simple gold dot; per-weapon reticles are U8).
	CrosshairImage = MakeImage(WidgetTree, TEXT("CrosshairImage"), FVector2D(6.0f, 6.0f));
	CrosshairImage->SetColorAndOpacity(HudGold());
	{
		FSlateBrush Dot;
		Dot.TintColor = FSlateColor(HudGold());
		Dot.DrawAs = ESlateBrushDrawType::Image;
		Dot.ImageSize = FVector2D(6.0f, 6.0f);
		CrosshairImage->SetBrush(Dot);
	}
	AnchorCorner(Canvas, CrosshairImage, 0.5f, 0.5f, 0.5f, 0.5f, FVector2D(0.0f, 0.0f));

	// Lower-left: plasmid ring + name.
	UVerticalBox* PlasmidCluster = WidgetTree->ConstructWidget<UVerticalBox>(
		UVerticalBox::StaticClass(), TEXT("PlasmidCluster"));
	PlasmidRingImage = MakeImage(WidgetTree, TEXT("PlasmidRingImage"), FVector2D(72.0f, 72.0f));
	if (UVerticalBoxSlot* RingSlot = PlasmidCluster->AddChildToVerticalBox(PlasmidRingImage))
	{
		RingSlot->SetHorizontalAlignment(HAlign_Left);
	}
	PlasmidText = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("PlasmidText"));
	PlasmidText->SetText(FText::GetEmpty());
	PlasmidText->SetFont(MakeHudFont(14));
	PlasmidText->SetColorAndOpacity(FSlateColor(FLinearColor(1.0f, 0.72f, 0.35f, 1.0f)));
	if (UVerticalBoxSlot* PlasmidTextSlot = PlasmidCluster->AddChildToVerticalBox(PlasmidText))
	{
		PlasmidTextSlot->SetPadding(FMargin(0.0f, 4.0f, 0.0f, 0.0f));
	}
	AnchorCorner(Canvas, PlasmidCluster, 0.0f, 1.0f, 0.0f, 1.0f, FVector2D(24.0f, -24.0f));

	// Lower-right: weapon ring + name always; HUD digits only when bEnforceAmmo.
	AmmoPanel = WidgetTree->ConstructWidget<UBorder>(UBorder::StaticClass(), TEXT("AmmoPanel"));
	AmmoPanel->SetBrushColor(FLinearColor(0.0f, 0.0f, 0.0f, 0.0f));
	AmmoPanel->SetPadding(FMargin(0.0f));
	UHorizontalBox* WeaponRow = WidgetTree->ConstructWidget<UHorizontalBox>(
		UHorizontalBox::StaticClass(), TEXT("WeaponRow"));
	AmmoPanel->SetContent(WeaponRow);

	UVerticalBox* AmmoTextCol = WidgetTree->ConstructWidget<UVerticalBox>(
		UVerticalBox::StaticClass(), TEXT("AmmoTextCol"));
	AmmoWeaponNameText = WidgetTree->ConstructWidget<UTextBlock>(
		UTextBlock::StaticClass(), TEXT("AmmoWeaponNameText"));
	AmmoWeaponNameText->SetText(FText::GetEmpty());
	AmmoWeaponNameText->SetJustification(ETextJustify::Right);
	AmmoWeaponNameText->SetFont(MakeHudFont(14, true));
	AmmoWeaponNameText->SetColorAndOpacity(FSlateColor(HudWhite()));
	if (UVerticalBoxSlot* NameSlot = AmmoTextCol->AddChildToVerticalBox(AmmoWeaponNameText))
	{
		NameSlot->SetHorizontalAlignment(HAlign_Right);
		NameSlot->SetPadding(FMargin(0.0f, 0.0f, 0.0f, 4.0f));
	}

	AmmoDigitsColumn = WidgetTree->ConstructWidget<UVerticalBox>(
		UVerticalBox::StaticClass(), TEXT("AmmoDigitsColumn"));
	AmmoMagDigits = WidgetTree->ConstructWidget<UHorizontalBox>(
		UHorizontalBox::StaticClass(), TEXT("AmmoMagDigits"));
	AmmoMagDigitImages.Reset(MaxMagDigits);
	for (int32 i = 0; i < MaxMagDigits; ++i)
	{
		UImage* DigitImg = MakeImage(
			WidgetTree,
			*FString::Printf(TEXT("MagDigit_%d"), i),
			FVector2D(MagDigitWidth, MagDigitHeight));
		DigitImg->SetVisibility(ESlateVisibility::Collapsed);
		AmmoMagDigits->AddChildToHorizontalBox(DigitImg);
		AmmoMagDigitImages.Add(DigitImg);
	}
	if (UVerticalBoxSlot* MagSlot = AmmoDigitsColumn->AddChildToVerticalBox(AmmoMagDigits))
	{
		MagSlot->SetHorizontalAlignment(HAlign_Right);
	}

	UHorizontalBox* ReserveRow = WidgetTree->ConstructWidget<UHorizontalBox>(
		UHorizontalBox::StaticClass(), TEXT("ReserveRow"));
	AmmoReservePrefixText = WidgetTree->ConstructWidget<UTextBlock>(
		UTextBlock::StaticClass(), TEXT("AmmoReservePrefix"));
	AmmoReservePrefixText->SetText(FText::FromString(TEXT("/ ")));
	AmmoReservePrefixText->SetFont(MakeHudFont(16));
	AmmoReservePrefixText->SetColorAndOpacity(FSlateColor(HudWhite()));
	ReserveRow->AddChildToHorizontalBox(AmmoReservePrefixText);
	AmmoReserveDigits = WidgetTree->ConstructWidget<UHorizontalBox>(
		UHorizontalBox::StaticClass(), TEXT("AmmoReserveDigits"));
	AmmoReserveDigitImages.Reset(MaxReserveDigits);
	for (int32 i = 0; i < MaxReserveDigits; ++i)
	{
		UImage* DigitImg = MakeImage(
			WidgetTree,
			*FString::Printf(TEXT("ReserveDigit_%d"), i),
			FVector2D(ReserveDigitWidth, ReserveDigitHeight));
		DigitImg->SetVisibility(ESlateVisibility::Collapsed);
		AmmoReserveDigits->AddChildToHorizontalBox(DigitImg);
		AmmoReserveDigitImages.Add(DigitImg);
	}
	ReserveRow->AddChildToHorizontalBox(AmmoReserveDigits);
	if (UVerticalBoxSlot* ReserveSlot = AmmoDigitsColumn->AddChildToVerticalBox(ReserveRow))
	{
		ReserveSlot->SetHorizontalAlignment(HAlign_Right);
		ReserveSlot->SetPadding(FMargin(0.0f, 2.0f, 0.0f, 0.0f));
	}
	if (UVerticalBoxSlot* DigitsColSlot = AmmoTextCol->AddChildToVerticalBox(AmmoDigitsColumn))
	{
		DigitsColSlot->SetHorizontalAlignment(HAlign_Right);
	}

	if (UHorizontalBoxSlot* TextColSlot = WeaponRow->AddChildToHorizontalBox(AmmoTextCol))
	{
		TextColSlot->SetVerticalAlignment(VAlign_Bottom);
		TextColSlot->SetPadding(FMargin(0.0f, 0.0f, 10.0f, 0.0f));
	}
	WeaponRingImage = MakeImage(WidgetTree, TEXT("WeaponRingImage"), FVector2D(72.0f, 72.0f));
	if (UHorizontalBoxSlot* WRingSlot = WeaponRow->AddChildToHorizontalBox(WeaponRingImage))
	{
		WRingSlot->SetVerticalAlignment(VAlign_Bottom);
	}

	AnchorCorner(Canvas, AmmoPanel, 1.0f, 1.0f, 1.0f, 1.0f, FVector2D(-24.0f, -24.0f));

	EnsureHudTextures();
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

void UShockHudWidget::SetMeterFill(
	UProgressBar* FillBar,
	float Percent,
	const FLinearColor& Tint) const
{
	if (!FillBar)
	{
		return;
	}
	const float Clamped = FMath::Clamp(Percent, 0.0f, 1.0f);
	FillBar->SetPercent(Clamped);
	FillBar->SetFillColorAndOpacity(Tint);
	FillBar->SetVisibility(
		Clamped > KINDA_SMALL_NUMBER ? ESlateVisibility::HitTestInvisible : ESlateVisibility::Collapsed);
}

void UShockHudWidget::SetDigitString(
	UHorizontalBox* Box,
	const TArray<TObjectPtr<UImage>>& Slots,
	const FString& Digits,
	float Scale) const
{
	if (!Box)
	{
		return;
	}
	const float W = (Scale > 0.9f) ? MagDigitWidth : ReserveDigitWidth;
	const float H = (Scale > 0.9f) ? MagDigitHeight : ReserveDigitHeight;
	for (int32 i = 0; i < Slots.Num(); ++i)
	{
		UImage* Img = Slots[i];
		if (!Img)
		{
			continue;
		}
		if (i >= Digits.Len())
		{
			Img->SetVisibility(ESlateVisibility::Collapsed);
			continue;
		}
		const TCHAR Ch = Digits[i];
		if (Ch < TEXT('0') || Ch > TEXT('9'))
		{
			Img->SetVisibility(ESlateVisibility::Collapsed);
			continue;
		}
		const int32 Digit = Ch - TEXT('0');
		UTexture2D* Tex = DigitTextures[Digit];
		if (!Tex)
		{
			Img->SetVisibility(ESlateVisibility::Collapsed);
			continue;
		}
		Img->SetBrushFromTexture(Tex, true);
		Img->SetBrushSize(FVector2D(W, H));
		Img->SetColorAndOpacity(FLinearColor::White);
		Img->SetVisibility(ESlateVisibility::HitTestInvisible);
	}
}

void UShockHudWidget::SetCountDigit(UImage* DigitImage, int32 Count) const
{
	if (!DigitImage)
	{
		return;
	}
	const int32 Clamped = FMath::Clamp(Count, 0, 9);
	UTexture2D* Tex = DigitTextures[Clamped];
	if (!Tex)
	{
		DigitImage->SetVisibility(ESlateVisibility::Collapsed);
		return;
	}
	DigitImage->SetBrushFromTexture(Tex, true);
	DigitImage->SetBrushSize(FVector2D(CountDigitWidth, CountDigitHeight));
	DigitImage->SetColorAndOpacity(FLinearColor::White);
	DigitImage->SetVisibility(ESlateVisibility::HitTestInvisible);
}

void UShockHudWidget::ApplyDamageFlashVisuals(bool bFlashing)
{
	const FLinearColor Color = bFlashing ? HudDamageEdge() : FLinearColor(0.0f, 0.0f, 0.0f, 0.0f);
	if (DamageFlashLeft)
	{
		DamageFlashLeft->SetBrushColor(Color);
	}
	if (DamageFlashRight)
	{
		DamageFlashRight->SetBrushColor(Color);
	}
	if (DamageFlashTop)
	{
		DamageFlashTop->SetBrushColor(Color);
	}
	if (DamageFlashBottom)
	{
		DamageFlashBottom->SetBrushColor(Color);
	}
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
		ApplyDamageFlashVisuals(false);
	}

	AShockPlayer* Player = ResolvePlayer();
	if (Player)
	{
		Player->EnsureHealthInitialized();
	}
	const float Health = Player ? Player->GetCurrentHealth() : 0.0f;
	const float MaxHealth = Player ? FMath::Max(Player->GetMaxHealth(), 1.0f) : 1.0f;

	if (LastObservedHealth >= 0.0f && Health < LastObservedHealth - KINDA_SMALL_NUMBER)
	{
		DamageFlashEndTime = Now + static_cast<double>(DamageFlashSeconds);
		ApplyDamageFlashVisuals(true);
	}
	else if (DamageFlashEndTime < 0.0)
	{
		ApplyDamageFlashVisuals(false);
	}
	LastObservedHealth = Health;

	CachedHealthText = FString::FromInt(FMath::RoundToInt(Health));
	SetMeterFill(HealthFillBar, Health / MaxHealth, HudHealthFill());

	const float Eve = Player ? Player->GetCurrentEve() : 0.0f;
	float MaxEve = Player ? Player->GetMaxEve() : 0.0f;
	if (MaxEve <= 0.0f)
	{
		MaxEve = FMath::Max(Eve, 1.0f);
	}
	CachedEveText = FString::Printf(TEXT("EVE %d"), FMath::RoundToInt(Eve));
	SetMeterFill(EveFillBar, Eve / MaxEve, HudEveFill());

	int32 KitCount = 0;
	int32 HypoCount = 0;
	int32 Money = 0;
	if (Player)
	{
		KitCount = Player->GetInventoryStack(FName(TEXT("FirstAidKit")));
		HypoCount = Player->GetInventoryStack(FName(TEXT("EveHypo")));
		Money = Player->GetMoney();
	}
	SetCountDigit(KitCountDigit, KitCount);
	SetCountDigit(HypoCountDigit, HypoCount);
	CachedConsumablesText = FString::Printf(
		TEXT("Kit %d  Hypo %d  $%d"),
		KitCount,
		HypoCount,
		Money);

	if (PlasmidText)
	{
		FString PlasmidLabel;
		if (Player)
		{
			if (const UShockPlasmid* ActivePlasmid = Player->GetActivePlasmid())
			{
				PlasmidLabel = ActivePlasmid->PlasmidName.ToString();
			}
		}
		CachedPlasmidText = PlasmidLabel;
		PlasmidText->SetText(FText::FromString(CachedPlasmidText));
		PlasmidText->SetVisibility(
			PlasmidLabel.IsEmpty() ? ESlateVisibility::Collapsed : ESlateVisibility::HitTestInvisible);
	}

	AShockWeapon* Weapon = ResolveEquippedWeapon(Player);
	const bool bHasWeapon = Weapon != nullptr;
	const bool bShowAmmo = Weapon && Weapon->bEnforceAmmo;
	bAmmoPanelVisible = bHasWeapon;
	bAmmoDigitsVisible = bShowAmmo;
	if (AmmoPanel)
	{
		AmmoPanel->SetVisibility(
			bHasWeapon ? ESlateVisibility::HitTestInvisible : ESlateVisibility::Collapsed);
	}

	if (!bHasWeapon)
	{
		CachedAmmoMagText = TEXT("");
		CachedWeaponNameText = TEXT("");
		CachedAmmoReserveText = TEXT("");
		if (AmmoWeaponNameText)
		{
			AmmoWeaponNameText->SetText(FText::GetEmpty());
		}
		if (AmmoDigitsColumn)
		{
			AmmoDigitsColumn->SetVisibility(ESlateVisibility::Collapsed);
		}
		return;
	}

	CachedWeaponNameText = Weapon->GetWeaponDefName().IsNone()
		? TEXT("Weapon")
		: Weapon->GetWeaponDefName().ToString();
	if (AmmoWeaponNameText)
	{
		AmmoWeaponNameText->SetText(FText::FromString(CachedWeaponNameText));
		AmmoWeaponNameText->SetVisibility(ESlateVisibility::HitTestInvisible);
	}

	if (!bShowAmmo)
	{
		CachedAmmoMagText = TEXT("");
		CachedAmmoReserveText = TEXT("");
		if (AmmoDigitsColumn)
		{
			AmmoDigitsColumn->SetVisibility(ESlateVisibility::Collapsed);
		}
		return;
	}

	if (AmmoDigitsColumn)
	{
		AmmoDigitsColumn->SetVisibility(ESlateVisibility::HitTestInvisible);
	}
	const int32 Mag = Weapon->GetRoundsInMagazine();
	const int32 Reserve = Weapon->GetReserveAmmo();
	CachedAmmoMagText = FString::FromInt(Mag);
	CachedAmmoReserveText = FString::Printf(TEXT("/ %d"), Reserve);
	SetDigitString(AmmoMagDigits, AmmoMagDigitImages, CachedAmmoMagText, 1.0f);
	SetDigitString(AmmoReserveDigits, AmmoReserveDigitImages, FString::FromInt(Reserve), 0.55f);
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

bool UShockHudWidget::HasHealthMeterFrame() const
{
	return MeterFrameTexture != nullptr && BrushHasTexture(HealthMeterFrame);
}

bool UShockHudWidget::HasEveMeterFrame() const
{
	return MeterFrameTexture != nullptr && BrushHasTexture(EveMeterFrame);
}

bool UShockHudWidget::HasDigitTextures() const
{
	for (int32 Digit = 0; Digit < 10; ++Digit)
	{
		if (DigitTextures[Digit] != nullptr)
		{
			return true;
		}
	}
	return false;
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
	Weapon->SetWeaponDefNameForVerify(FName(TEXT("Pistol")));
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
	if (!Hud->HasHealthMeterFrame())
	{
		LastHudVerifyError = TEXT(
			"health meter frame UImage has null texture — run tools/ue5/import_bioshock_ui.py "
			"into /Game/BioShockUI/HUD");
		Hud->RemoveFromParent();
		Player->Destroy();
		Weapon->Destroy();
		return false;
	}
	if (!Hud->HasEveMeterFrame())
	{
		LastHudVerifyError = TEXT(
			"eve meter frame UImage has null texture — run tools/ue5/import_bioshock_ui.py "
			"into /Game/BioShockUI/HUD");
		Hud->RemoveFromParent();
		Player->Destroy();
		Weapon->Destroy();
		return false;
	}
	if (!Hud->HasDigitTextures())
	{
		LastHudVerifyError = TEXT(
			"HUD digit textures missing — run tools/ue5/import_bioshock_ui.py "
			"into /Game/BioShockUI/HUD");
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
	if (!Hud->IsAmmoDigitsVisible())
	{
		LastHudVerifyError = TEXT("ammo digits hidden with enforce ammo weapon");
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
	const FString ExpectedReserveText = FString::Printf(TEXT("/ %d"), ExpectedReserve);
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
			 "health_frame=%d eve_frame=%d digits=%d"),
		ExpectedHealth,
		ExpectedMag,
		ExpectedReserve,
		ExpectedHealthAfter,
		Hud->IsInViewport() ? 1 : 0,
		Hud->HasHealthMeterFrame() ? 1 : 0,
		Hud->HasEveMeterFrame() ? 1 : 0,
		Hud->HasDigitTextures() ? 1 : 0);

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
	NoAmmoWeapon->SetWeaponDefNameForVerify(FName(TEXT("Wrench")));
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
	if (!NoAmmoHud->IsAmmoPanelVisible())
	{
		LastHudVerifyError = TEXT("weapon cluster hidden when bEnforceAmmo false (should show ring+name)");
		NoAmmoPlayer->Destroy();
		NoAmmoWeapon->Destroy();
		return false;
	}
	if (NoAmmoHud->IsAmmoDigitsVisible())
	{
		LastHudVerifyError = TEXT("ammo digits visible when bEnforceAmmo false");
		NoAmmoPlayer->Destroy();
		NoAmmoWeapon->Destroy();
		return false;
	}
	if (NoAmmoHud->GetDisplayedWeaponNameText() != TEXT("Wrench"))
	{
		LastHudVerifyError = FString::Printf(
			TEXT("weapon name %s != Wrench"),
			*NoAmmoHud->GetDisplayedWeaponNameText());
		NoAmmoPlayer->Destroy();
		NoAmmoWeapon->Destroy();
		return false;
	}
	NoAmmoPlayer->Destroy();
	NoAmmoWeapon->Destroy();
	return true;
}
