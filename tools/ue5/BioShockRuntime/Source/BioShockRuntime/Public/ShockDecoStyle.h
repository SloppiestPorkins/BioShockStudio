#pragma once

#include "Kismet/BlueprintFunctionLibrary.h"
#include "Styling/SlateBrush.h"
#include "Styling/SlateTypes.h"
#include "ShockDecoStyle.generated.h"

class UBorder;
class UButton;
class UImage;
class UTexture2D;

/**
 * Shared BioShock Deco chrome (Phase U8b) — static brushes / button styles from
 * /Game/BioShockUI/Deco textures. Not a widget; menus call these apply helpers.
 */
UCLASS()
class BIOSHOCKRUNTIME_API UShockDecoStyle : public UBlueprintFunctionLibrary
{
	GENERATED_BODY()

public:
	/** Hand-measured 9-slice margins (UV 0–1) on cropped Deco bitmaps. */
	static FMargin ListButtonMargin();
	static FMargin PanelFrameMargin();
	static FMargin BannerMargin();
	static FMargin NameplateMargin();
	static FMargin RowPlateMargin();

	static FLinearColor GoldColor();
	static FLinearColor CreamColor();
	static FLinearColor DimColor();
	static FLinearColor EmptySlotTint();

	static UTexture2D* LoadListButton(bool bHovered);
	static UTexture2D* LoadPanelFrame();
	static UTexture2D* LoadPanelFill();
	static UTexture2D* LoadNameplate(bool bWide);
	static UTexture2D* LoadBanner();
	static UTexture2D* LoadSlotGrid();
	static UTexture2D* LoadRowPlate(bool bAlt = false);
	static UTexture2D* LoadScrollbar();
	static UTexture2D* LoadChevron();

	static FSlateBrush MakeBoxBrush(
		UTexture2D* Texture,
		const FMargin& Margin,
		FVector2D ImageSize,
		FLinearColor Tint = FLinearColor::White);

	static FSlateBrush MakeListButtonBrush(bool bHovered, FVector2D Size = FVector2D(420.0f, 48.0f));
	static FSlateBrush MakePanelFrameBrush(FVector2D Size = FVector2D(900.0f, 640.0f));
	static FSlateBrush MakePanelFillBrush(FVector2D Size = FVector2D(900.0f, 640.0f));
	static FSlateBrush MakeBannerBrush(FVector2D Size = FVector2D(480.0f, 100.0f));
	static FSlateBrush MakeNameplateBrush(bool bWide, FVector2D Size = FVector2D(320.0f, 36.0f));
	static FSlateBrush MakeRowPlateBrush(FVector2D Size = FVector2D(520.0f, 56.0f));
	static FSlateBrush MakeSlotGridBrush(FVector2D Size = FVector2D(280.0f, 360.0f));
	static FSlateBrush MakeVignetteBrush();

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Deco")
	static void ApplyListButtonStyle(UButton* Button, bool bSelected = false);

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Deco")
	static void ApplyImageBrush(UImage* Image, const FSlateBrush& Brush);

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Deco")
	static void ApplyBanner(UImage* Image, FVector2D Size = FVector2D(480.0f, 100.0f));

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Deco")
	static void ApplyNameplate(UImage* Image, bool bWide = false, FVector2D Size = FVector2D(320.0f, 36.0f));

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Deco")
	static void ApplyPanelFrame(UImage* Image, FVector2D Size = FVector2D(900.0f, 640.0f));

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Deco")
	static void ApplyRowPlate(UImage* Image, FVector2D Size = FVector2D(520.0f, 56.0f));

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Deco")
	static void ApplySlotGrid(UImage* Image, FVector2D Size = FVector2D(280.0f, 360.0f));

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Deco")
	static void ApplyVignetteBackground(UBorder* Border);

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Deco")
	static bool HasRequiredTextures();

	/** Clear HUD meters sit at ~16px margin with ~100px height — push overlays below. */
	static constexpr float HudClearTopPadding = 210.0f;
	static constexpr float StationPanelWidth = 900.0f;
	static constexpr float StationPanelHeight = 640.0f;
};
