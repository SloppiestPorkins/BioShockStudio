#include "ShockHudWidget.h"

#include "ShockDamageLibrary.h"
#include "ShockPlasmid.h"
#include "ShockPlayer.h"
#include "ShockPawn.h"
#include "ShockUiDisplayNames.h"
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
#include "Materials/MaterialInstanceDynamic.h"
#include "Materials/MaterialInterface.h"
#include "Misc/PackageName.h"
#include "Styling/CoreStyle.h"
#include "TimerManager.h"
#include "UObject/SoftObjectPath.h"

FString UShockHudWidget::LastHudVerifyError;

namespace
{
constexpr float RefreshIntervalSeconds = 0.1f;
constexpr float DamageFlashSeconds = 0.35f;

// Slightly under U2b's 560×116 — tucked into the corner like BioShock's HUD.
constexpr float MeterDisplayWidth = 480.0f;
constexpr float MeterDisplayHeight = 100.0f;
// Highlight line sits just under the rim (punch tighten in import is the overshoot fix).
constexpr float FillInsetLeft = 4.0f;
constexpr float FillInsetTop = 3.0f;
constexpr float FillInsetRight = 4.0f;

constexpr float CapIconSize = 30.0f;
constexpr float CountDigitWidth = 18.0f;
constexpr float CountDigitHeight = 36.0f;
constexpr int32 MaxCountDigits = 2;

constexpr float MagDigitWidth = 24.0f;
constexpr float MagDigitHeight = 48.0f;
constexpr float ReserveDigitWidth = 14.0f;
constexpr float ReserveDigitHeight = 28.0f;
constexpr int32 MaxMagDigits = 3;
constexpr int32 MaxReserveDigits = 4;

constexpr float ClusterRingSize = 64.0f;
constexpr float CornerMargin = 16.0f;

const TCHAR* MeterFrameTexturePath = TEXT("/Game/BioShockUI/HUD/T_Hud_MeterFrame.T_Hud_MeterFrame");
const TCHAR* FillMaskTexturePath = TEXT("/Game/BioShockUI/HUD/T_Hud_FillMask.T_Hud_FillMask");
const TCHAR* LiquidFillMaterialPath = TEXT("/Game/BioShockUI/HUD/M_Hud_LiquidFill.M_Hud_LiquidFill");
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
	Brush.DrawAs = ESlateBrushDrawType::Image;
	Brush.Tiling = ESlateBrushTileType::NoTile;
	Image->SetBrush(Brush);
	Image->SetDesiredSizeOverride(FVector2D(MeterDisplayWidth, MeterDisplayHeight));
}

void ApplyFillBarStyle(
	UProgressBar* Bar,
	UTexture2D* Mask,
	UMaterialInstanceDynamic* FillMID,
	const FLinearColor& Tint)
{
	if (!Bar)
	{
		return;
	}
	FProgressBarStyle Style = Bar->GetWidgetStyle();
	FSlateBrush Fill;
	if (FillMID)
	{
		FillMID->SetTextureParameterValue(TEXT("FillMask"), Mask);
		FillMID->SetVectorParameterValue(TEXT("Tint"), Tint);
		Fill.SetResourceObject(FillMID);
	}
	else if (Mask)
	{
		Fill.SetResourceObject(Mask);
		Fill.TintColor = FSlateColor(Tint);
	}
	else
	{
		return;
	}
	Fill.ImageSize = FVector2D(MeterDisplayWidth, MeterDisplayHeight);
	Fill.DrawAs = ESlateBrushDrawType::Image;
	Fill.Tiling = ESlateBrushTileType::NoTile;
	Style.SetFillImage(Fill);
	FSlateBrush Bg;
	Bg.DrawAs = ESlateBrushDrawType::NoDrawType;
	Style.SetBackgroundImage(Bg);
	Style.SetEnableFillAnimation(false);
	Bar->SetWidgetStyle(Style);
	Bar->SetFillColorAndOpacity(FillMID ? FLinearColor::White : Tint);
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
 * Meter stack: liquid ProgressBar UNDER the punched frame, then cap icon + digit row
 * on the left bulb. Fill is inset so 100% sits flush inside the pill ends.
 */
UOverlay* MakeMeterStack(
	UWidgetTree* Tree,
	FName OverlayName,
	UImage*& OutFrame,
	FName FrameName,
	UProgressBar*& OutFillBar,
	FName FillBarName,
	UImage*& OutHighlight,
	FName HighlightName,
	UImage*& OutCapIcon,
	FName CapIconName,
	UHorizontalBox*& OutCountDigits,
	FName CountDigitsName,
	TArray<TObjectPtr<UImage>>& OutCountDigitImages)
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

	OutHighlight = MakeImage(Tree, HighlightName, FVector2D(MeterDisplayWidth, 2.0f));
	OutHighlight->SetColorAndOpacity(FLinearColor(1.0f, 1.0f, 1.0f, 0.28f));
	{
		FSlateBrush Line;
		Line.TintColor = FSlateColor(FLinearColor(1.0f, 1.0f, 1.0f, 0.28f));
		Line.DrawAs = ESlateBrushDrawType::Image;
		Line.ImageSize = FVector2D(8.0f, 2.0f);
		OutHighlight->SetBrush(Line);
	}
	if (UOverlaySlot* HiSlot = Overlay->AddChildToOverlay(OutHighlight))
	{
		HiSlot->SetPadding(FMargin(FillInsetLeft + 18.0f, FillInsetTop + 4.0f, FillInsetRight + 18.0f, 0.0f));
		HiSlot->SetHorizontalAlignment(HAlign_Fill);
		HiSlot->SetVerticalAlignment(VAlign_Top);
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
	OutCountDigits = Tree->ConstructWidget<UHorizontalBox>(UHorizontalBox::StaticClass(), CountDigitsName);
	OutCountDigitImages.Reset(MaxCountDigits);
	for (int32 i = 0; i < MaxCountDigits; ++i)
	{
		UImage* DigitImg = MakeImage(
			Tree,
			*FString::Printf(TEXT("%s_%d"), *CountDigitsName.ToString(), i),
			FVector2D(CountDigitWidth, CountDigitHeight));
		DigitImg->SetVisibility(ESlateVisibility::Collapsed);
		OutCountDigits->AddChildToHorizontalBox(DigitImg);
		OutCountDigitImages.Add(DigitImg);
	}
	if (UHorizontalBoxSlot* DigitSlot = CapRow->AddChildToHorizontalBox(OutCountDigits))
	{
		DigitSlot->SetVerticalAlignment(VAlign_Center);
	}
	if (UOverlaySlot* CapRowSlot = Overlay->AddChildToOverlay(CapRow))
	{
		CapRowSlot->SetPadding(FMargin(18.0f, 0.0f, 0.0f, 0.0f));
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

UMaterialInstanceDynamic* UShockHudWidget::EnsureFillMID(
	TObjectPtr<UMaterialInstanceDynamic>& MidSlot,
	FName DebugName)
{
	if (MidSlot)
	{
		return MidSlot;
	}
	// M_Hud_LiquidFill (script-authored) renders invisible in-game — its UI material graph is not
	// right. Until it is fixed, take the flat tinted-mask fill (ApplyFillBarStyle's `else if (Mask)`
	// branch), which reads correctly. Restore by dropping bLiquidMaterialDisabled once it works.
	constexpr bool bLiquidMaterialDisabled = true;
	if (bLiquidMaterialDisabled || !LiquidFillMaterial)
	{
		return nullptr;
	}
	MidSlot = UMaterialInstanceDynamic::Create(LiquidFillMaterial, this, DebugName);
	return MidSlot;
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
	if (!LiquidFillMaterial)
	{
		// Optional — created by import_bioshock_ui._ensure_liquid_fill_material. Avoid LoadObject
		// spam when the asset has not been imported yet (gradient FillMask + highlight still work).
		static const FSoftObjectPath LiquidPath(LiquidFillMaterialPath);
		if (LiquidPath.ResolveObject() || FPackageName::DoesPackageExist(LiquidPath.GetLongPackageName()))
		{
			LiquidFillMaterial = Cast<UMaterialInterface>(LiquidPath.TryLoad());
		}
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

	UMaterialInstanceDynamic* HealthMid = EnsureFillMID(HealthFillMID, TEXT("HealthLiquidMID"));
	UMaterialInstanceDynamic* EveMid = EnsureFillMID(EveFillMID, TEXT("EveLiquidMID"));
	if (HealthFillBar && FillMaskTexture)
	{
		ApplyFillBarStyle(HealthFillBar, FillMaskTexture, HealthMid, HudHealthFill());
	}
	if (EveFillBar && FillMaskTexture)
	{
		ApplyFillBarStyle(EveFillBar, FillMaskTexture, EveMid, HudEveFill());
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
		PlasmidRingImage->SetBrushSize(FVector2D(ClusterRingSize, ClusterRingSize));
	}
	if (WeaponRingImage && BrassRingTexture)
	{
		WeaponRingImage->SetBrushFromTexture(BrassRingTexture, true);
		WeaponRingImage->SetBrushSize(FVector2D(ClusterRingSize, ClusterRingSize));
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

	VignetteImage = MakeImage(WidgetTree, TEXT("VignetteImage"), FVector2D(32.0f, 32.0f));
	VignetteImage->SetColorAndOpacity(FLinearColor(1.0f, 1.0f, 1.0f, 0.85f));
	if (UCanvasPanelSlot* VigSlot = Canvas->AddChildToCanvas(VignetteImage))
	{
		VigSlot->SetAnchors(FAnchors(0.0f, 1.0f, 1.0f, 1.0f));
		VigSlot->SetAlignment(FVector2D(0.5f, 1.0f));
		VigSlot->SetOffsets(FMargin(0.0f, -128.0f, 0.0f, 0.0f));
	}

	// Directional damage wedges (screen edges).
	DamageFlashLeft = MakeEdgeFlash(WidgetTree, TEXT("DamageFlashLeft"));
	if (UCanvasPanelSlot* L = Canvas->AddChildToCanvas(DamageFlashLeft))
	{
		L->SetAnchors(FAnchors(0.0f, 0.0f, 0.0f, 1.0f));
		L->SetOffsets(FMargin(0.0f, 0.0f, 72.0f, 0.0f));
	}
	DamageFlashRight = MakeEdgeFlash(WidgetTree, TEXT("DamageFlashRight"));
	if (UCanvasPanelSlot* R = Canvas->AddChildToCanvas(DamageFlashRight))
	{
		R->SetAnchors(FAnchors(1.0f, 0.0f, 1.0f, 1.0f));
		R->SetAlignment(FVector2D(1.0f, 0.0f));
		R->SetOffsets(FMargin(-72.0f, 0.0f, 0.0f, 0.0f));
	}
	DamageFlashTop = MakeEdgeFlash(WidgetTree, TEXT("DamageFlashTop"));
	if (UCanvasPanelSlot* T = Canvas->AddChildToCanvas(DamageFlashTop))
	{
		T->SetAnchors(FAnchors(0.0f, 0.0f, 1.0f, 0.0f));
		T->SetOffsets(FMargin(0.0f, 0.0f, 0.0f, 56.0f));
	}
	DamageFlashBottom = MakeEdgeFlash(WidgetTree, TEXT("DamageFlashBottom"));
	if (UCanvasPanelSlot* B = Canvas->AddChildToCanvas(DamageFlashBottom))
	{
		B->SetAnchors(FAnchors(0.0f, 1.0f, 1.0f, 1.0f));
		B->SetAlignment(FVector2D(0.0f, 1.0f));
		B->SetOffsets(FMargin(0.0f, -56.0f, 0.0f, 0.0f));
	}

	UVerticalBox* MeterCluster = WidgetTree->ConstructWidget<UVerticalBox>(
		UVerticalBox::StaticClass(), TEXT("MeterCluster"));

	UImage* HealthFramePtr = nullptr;
	UProgressBar* HealthFillBarPtr = nullptr;
	UImage* HealthHighlightPtr = nullptr;
	UImage* HealthCapPtr = nullptr;
	UHorizontalBox* KitDigitsPtr = nullptr;
	UOverlay* HealthMeter = MakeMeterStack(
		WidgetTree,
		TEXT("HealthMeterOverlay"),
		HealthFramePtr,
		TEXT("HealthMeterFrame"),
		HealthFillBarPtr,
		TEXT("HealthFillBar"),
		HealthHighlightPtr,
		TEXT("HealthFillHighlight"),
		HealthCapPtr,
		TEXT("HealthCapIcon"),
		KitDigitsPtr,
		TEXT("KitCountDigits"),
		KitCountDigitImages);
	HealthMeterFrame = HealthFramePtr;
	HealthFillBar = HealthFillBarPtr;
	HealthFillHighlight = HealthHighlightPtr;
	HealthCapIcon = HealthCapPtr;
	KitCountDigits = KitDigitsPtr;
	USizeBox* HealthSize = WidgetTree->ConstructWidget<USizeBox>(
		USizeBox::StaticClass(), TEXT("HealthMeterSize"));
	HealthSize->SetWidthOverride(MeterDisplayWidth);
	HealthSize->SetHeightOverride(MeterDisplayHeight);
	HealthSize->AddChild(HealthMeter);
	if (UVerticalBoxSlot* HealthRowSlot = MeterCluster->AddChildToVerticalBox(HealthSize))
	{
		HealthRowSlot->SetPadding(FMargin(0.0f, 0.0f, 0.0f, 6.0f));
	}

	UImage* EveFramePtr = nullptr;
	UProgressBar* EveFillBarPtr = nullptr;
	UImage* EveHighlightPtr = nullptr;
	UImage* EveCapPtr = nullptr;
	UHorizontalBox* HypoDigitsPtr = nullptr;
	UOverlay* EveMeter = MakeMeterStack(
		WidgetTree,
		TEXT("EveMeterOverlay"),
		EveFramePtr,
		TEXT("EveMeterFrame"),
		EveFillBarPtr,
		TEXT("EveFillBar"),
		EveHighlightPtr,
		TEXT("EveFillHighlight"),
		EveCapPtr,
		TEXT("EveCapIcon"),
		HypoDigitsPtr,
		TEXT("HypoCountDigits"),
		HypoCountDigitImages);
	EveMeterFrame = EveFramePtr;
	EveFillBar = EveFillBarPtr;
	EveFillHighlight = EveHighlightPtr;
	EveCapIcon = EveCapPtr;
	HypoCountDigits = HypoDigitsPtr;
	USizeBox* EveSize = WidgetTree->ConstructWidget<USizeBox>(
		USizeBox::StaticClass(), TEXT("EveMeterSize"));
	EveSize->SetWidthOverride(MeterDisplayWidth);
	EveSize->SetHeightOverride(MeterDisplayHeight);
	EveSize->AddChild(EveMeter);
	MeterCluster->AddChildToVerticalBox(EveSize);

	AnchorCorner(Canvas, MeterCluster, 0.0f, 0.0f, 0.0f, 0.0f, FVector2D(CornerMargin, CornerMargin));

	ToastText = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("ToastText"));
	ToastText->SetText(FText::GetEmpty());
	ToastText->SetFont(MakeHudFont(20, true));
	ToastText->SetColorAndOpacity(FSlateColor(HudGold()));
	ToastText->SetJustification(ETextJustify::Center);
	ToastText->SetVisibility(ESlateVisibility::Collapsed);
	AnchorCorner(Canvas, ToastText, 0.5f, 0.0f, 0.5f, 0.0f, FVector2D(0.0f, 36.0f));

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

	UVerticalBox* PlasmidCluster = WidgetTree->ConstructWidget<UVerticalBox>(
		UVerticalBox::StaticClass(), TEXT("PlasmidCluster"));
	PlasmidRingImage = MakeImage(WidgetTree, TEXT("PlasmidRingImage"), FVector2D(ClusterRingSize, ClusterRingSize));
	if (UVerticalBoxSlot* RingSlot = PlasmidCluster->AddChildToVerticalBox(PlasmidRingImage))
	{
		RingSlot->SetHorizontalAlignment(HAlign_Left);
	}
	PlasmidText = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("PlasmidText"));
	PlasmidText->SetText(FText::GetEmpty());
	PlasmidText->SetFont(MakeHudFont(13));
	PlasmidText->SetColorAndOpacity(FSlateColor(FLinearColor(1.0f, 0.72f, 0.35f, 1.0f)));
	if (UVerticalBoxSlot* PlasmidTextSlot = PlasmidCluster->AddChildToVerticalBox(PlasmidText))
	{
		PlasmidTextSlot->SetPadding(FMargin(0.0f, 4.0f, 0.0f, 0.0f));
	}
	AnchorCorner(Canvas, PlasmidCluster, 0.0f, 1.0f, 0.0f, 1.0f, FVector2D(CornerMargin, -CornerMargin));

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
	AmmoWeaponNameText->SetFont(MakeHudFont(13, true));
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
	if (UVerticalBoxSlot* ReserveSlot = AmmoDigitsColumn->AddChildToVerticalBox(AmmoReserveDigits))
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
		TextColSlot->SetPadding(FMargin(0.0f, 0.0f, 8.0f, 0.0f));
	}
	WeaponRingImage = MakeImage(WidgetTree, TEXT("WeaponRingImage"), FVector2D(ClusterRingSize, ClusterRingSize));
	if (UHorizontalBoxSlot* WRingSlot = WeaponRow->AddChildToHorizontalBox(WeaponRingImage))
	{
		WRingSlot->SetVerticalAlignment(VAlign_Bottom);
	}

	AnchorCorner(Canvas, AmmoPanel, 1.0f, 1.0f, 1.0f, 1.0f, FVector2D(-CornerMargin, -CornerMargin));

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
	UMaterialInstanceDynamic* FillMID,
	float Percent,
	const FLinearColor& Tint) const
{
	if (!FillBar)
	{
		return;
	}
	const float Clamped = FMath::Clamp(Percent, 0.0f, 1.0f);
	FillBar->SetPercent(Clamped);
	if (FillMID)
	{
		FillMID->SetVectorParameterValue(TEXT("Tint"), Tint);
		FillBar->SetFillColorAndOpacity(FLinearColor::White);
	}
	else
	{
		FillBar->SetFillColorAndOpacity(Tint);
	}
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

void UShockHudWidget::SetCountDigits(
	UHorizontalBox* Box,
	const TArray<TObjectPtr<UImage>>& Slots,
	int32 Count) const
{
	const int32 Clamped = FMath::Clamp(Count, 0, 99);
	SetDigitString(Box, Slots, FString::FromInt(Clamped), 0.7f);
	for (int32 i = 0; i < Slots.Num(); ++i)
	{
		if (UImage* Img = Slots[i])
		{
			if (Img->GetVisibility() != ESlateVisibility::Collapsed)
			{
				Img->SetBrushSize(FVector2D(CountDigitWidth, CountDigitHeight));
			}
		}
	}
}

void UShockHudWidget::ApplyDamageFlashVisuals(bool bLeft, bool bRight, bool bTop, bool bBottom)
{
	const FLinearColor Off(0.0f, 0.0f, 0.0f, 0.0f);
	const FLinearColor On = HudDamageEdge();
	if (DamageFlashLeft)
	{
		DamageFlashLeft->SetBrushColor(bLeft ? On : Off);
	}
	if (DamageFlashRight)
	{
		DamageFlashRight->SetBrushColor(bRight ? On : Off);
	}
	if (DamageFlashTop)
	{
		DamageFlashTop->SetBrushColor(bTop ? On : Off);
	}
	if (DamageFlashBottom)
	{
		DamageFlashBottom->SetBrushColor(bBottom ? On : Off);
	}
}

void UShockHudWidget::FlashDamageFromHit(AShockPlayer* Player)
{
	FVector SourceWorld;
	const bool bHasSource = Player && Player->TryGetLastDamageSourceWorld(SourceWorld);
	if (!bHasSource)
	{
		bDamageFlashLeft = bDamageFlashRight = bDamageFlashTop = bDamageFlashBottom = true;
		ApplyDamageFlashVisuals(true, true, true, true);
		UE_LOG(
			LogTemp,
			Display,
			TEXT("BIOSHOCK_HUD_DAMAGE_DIR none — flashing all four edges (damage event had no source)"));
		return;
	}

	FVector ViewLoc = Player->GetActorLocation();
	FRotator ViewRot = Player->GetActorRotation();
	if (APlayerController* PC = GetOwningPlayer())
	{
		PC->GetPlayerViewPoint(ViewLoc, ViewRot);
	}
	else if (Player->GetController())
	{
		Player->GetController()->GetPlayerViewPoint(ViewLoc, ViewRot);
	}

	const FVector ToSource = (SourceWorld - ViewLoc).GetSafeNormal2D();
	const FVector Forward = ViewRot.Vector().GetSafeNormal2D();
	const FVector Right = FRotationMatrix(ViewRot).GetScaledAxis(EAxis::Y).GetSafeNormal2D();
	const float FwdDot = FVector::DotProduct(ToSource, Forward);
	const float RightDot = FVector::DotProduct(ToSource, Right);

	bDamageFlashTop = FwdDot > 0.35f;
	bDamageFlashBottom = FwdDot < -0.35f;
	bDamageFlashRight = RightDot > 0.35f;
	bDamageFlashLeft = RightDot < -0.35f;
	if (!bDamageFlashLeft && !bDamageFlashRight && !bDamageFlashTop && !bDamageFlashBottom)
	{
		// Nearly on-axis but weak — pick the dominant axis.
		if (FMath::Abs(FwdDot) >= FMath::Abs(RightDot))
		{
			bDamageFlashTop = FwdDot >= 0.0f;
			bDamageFlashBottom = FwdDot < 0.0f;
		}
		else
		{
			bDamageFlashRight = RightDot >= 0.0f;
			bDamageFlashLeft = RightDot < 0.0f;
		}
	}
	ApplyDamageFlashVisuals(bDamageFlashLeft, bDamageFlashRight, bDamageFlashTop, bDamageFlashBottom);
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
		bDamageFlashLeft = bDamageFlashRight = bDamageFlashTop = bDamageFlashBottom = false;
		ApplyDamageFlashVisuals(false, false, false, false);
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
		FlashDamageFromHit(Player);
	}
	else if (DamageFlashEndTime < 0.0)
	{
		ApplyDamageFlashVisuals(false, false, false, false);
	}
	else
	{
		ApplyDamageFlashVisuals(bDamageFlashLeft, bDamageFlashRight, bDamageFlashTop, bDamageFlashBottom);
	}
	LastObservedHealth = Health;

	CachedHealthText = FString::FromInt(FMath::RoundToInt(Health));
	SetMeterFill(HealthFillBar, HealthFillMID, Health / MaxHealth, HudHealthFill());
	if (HealthFillHighlight)
	{
		HealthFillHighlight->SetVisibility(
			Health > KINDA_SMALL_NUMBER ? ESlateVisibility::HitTestInvisible : ESlateVisibility::Collapsed);
	}

	const float Eve = Player ? Player->GetCurrentEve() : 0.0f;
	float MaxEve = Player ? Player->GetMaxEve() : 0.0f;
	if (MaxEve <= 0.0f)
	{
		MaxEve = FMath::Max(Eve, 1.0f);
	}
	CachedEveText = FString::Printf(TEXT("EVE %d"), FMath::RoundToInt(Eve));
	SetMeterFill(EveFillBar, EveFillMID, Eve / MaxEve, HudEveFill());
	if (EveFillHighlight)
	{
		EveFillHighlight->SetVisibility(
			Eve > KINDA_SMALL_NUMBER ? ESlateVisibility::HitTestInvisible : ESlateVisibility::Collapsed);
	}

	int32 KitCount = 0;
	int32 HypoCount = 0;
	int32 Money = 0;
	if (Player)
	{
		KitCount = Player->GetInventoryStack(FName(TEXT("FirstAidKit")));
		HypoCount = Player->GetInventoryStack(FName(TEXT("EveHypo")));
		Money = Player->GetMoney();
	}
	SetCountDigits(KitCountDigits, KitCountDigitImages, KitCount);
	SetCountDigits(HypoCountDigits, HypoCountDigitImages, HypoCount);
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
				PlasmidLabel = ShockUiDisplayNames::Friendly(ActivePlasmid->PlasmidName);
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
		: ShockUiDisplayNames::Friendly(Weapon->GetWeaponDefName());
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
