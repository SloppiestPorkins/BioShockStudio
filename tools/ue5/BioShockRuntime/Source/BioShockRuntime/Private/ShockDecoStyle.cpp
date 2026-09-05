#include "ShockDecoStyle.h"

#include "Components/Border.h"
#include "Components/Button.h"
#include "Components/Image.h"
#include "Engine/Texture2D.h"

namespace ShockDecoStylePrivate
{
UTexture2D* Load(const TCHAR* Path)
{
	return LoadObject<UTexture2D>(nullptr, Path);
}

FSlateBrush MakeImage(UTexture2D* Tex, FVector2D Size, FLinearColor Tint)
{
	FSlateBrush Brush;
	Brush.DrawAs = ESlateBrushDrawType::Image;
	Brush.Tiling = ESlateBrushTileType::NoTile;
	Brush.ImageSize = Size;
	Brush.TintColor = FSlateColor(Tint);
	if (Tex)
	{
		Brush.SetResourceObject(Tex);
	}
	return Brush;
}
}

FMargin UShockDecoStyle::ListButtonMargin()
{
	// Cropped pausePC 565/567 horizontal plates — end caps ~12% of width.
	return FMargin(0.12f, 0.28f, 0.12f, 0.28f);
}

FMargin UShockDecoStyle::PanelFrameMargin()
{
	// Cropped mapsPC 1811 window frame.
	return FMargin(0.08f, 0.10f, 0.08f, 0.12f);
}

FMargin UShockDecoStyle::BannerMargin()
{
	// Cropped pausePC 565.
	return FMargin(0.08f, 0.18f, 0.08f, 0.18f);
}

FMargin UShockDecoStyle::NameplateMargin()
{
	return FMargin(0.12f, 0.20f, 0.12f, 0.20f);
}

FMargin UShockDecoStyle::RowPlateMargin()
{
	// Cropped GeneBankPC 159.
	return FMargin(0.10f, 0.22f, 0.10f, 0.22f);
}

FLinearColor UShockDecoStyle::GoldColor()
{
	return FLinearColor(0.92f, 0.78f, 0.35f, 1.0f);
}

FLinearColor UShockDecoStyle::CreamColor()
{
	return FLinearColor(0.92f, 0.88f, 0.75f, 1.0f);
}

FLinearColor UShockDecoStyle::DimColor()
{
	return FLinearColor(0.55f, 0.50f, 0.40f, 1.0f);
}

FLinearColor UShockDecoStyle::EmptySlotTint()
{
	return FLinearColor(0.35f, 0.35f, 0.38f, 0.85f);
}

UTexture2D* UShockDecoStyle::LoadListButton(bool bHovered)
{
	return bHovered
		? ShockDecoStylePrivate::Load(
			  TEXT("/Game/BioShockUI/Deco/T_Deco_ListButtonHover.T_Deco_ListButtonHover"))
		: ShockDecoStylePrivate::Load(
			  TEXT("/Game/BioShockUI/Deco/T_Deco_ListButton.T_Deco_ListButton"));
}

UTexture2D* UShockDecoStyle::LoadPanelFrame()
{
	return ShockDecoStylePrivate::Load(
		TEXT("/Game/BioShockUI/Deco/T_Deco_PanelFrame.T_Deco_PanelFrame"));
}

UTexture2D* UShockDecoStyle::LoadPanelFill()
{
	return ShockDecoStylePrivate::Load(
		TEXT("/Game/BioShockUI/Deco/T_Deco_PanelFill.T_Deco_PanelFill"));
}

UTexture2D* UShockDecoStyle::LoadNameplate(bool bWide)
{
	return bWide
		? ShockDecoStylePrivate::Load(
			  TEXT("/Game/BioShockUI/Deco/T_Deco_NameplateWide.T_Deco_NameplateWide"))
		: ShockDecoStylePrivate::Load(
			  TEXT("/Game/BioShockUI/Deco/T_Deco_Nameplate.T_Deco_Nameplate"));
}

UTexture2D* UShockDecoStyle::LoadBanner()
{
	return ShockDecoStylePrivate::Load(TEXT("/Game/BioShockUI/Deco/T_Deco_Banner.T_Deco_Banner"));
}

UTexture2D* UShockDecoStyle::LoadSlotGrid()
{
	return ShockDecoStylePrivate::Load(
		TEXT("/Game/BioShockUI/Deco/T_Deco_SlotGrid.T_Deco_SlotGrid"));
}

UTexture2D* UShockDecoStyle::LoadRowPlate(bool bAlt)
{
	return bAlt
		? ShockDecoStylePrivate::Load(
			  TEXT("/Game/BioShockUI/Deco/T_Deco_RowPlateAlt.T_Deco_RowPlateAlt"))
		: ShockDecoStylePrivate::Load(
			  TEXT("/Game/BioShockUI/Deco/T_Deco_RowPlate.T_Deco_RowPlate"));
}

UTexture2D* UShockDecoStyle::LoadScrollbar()
{
	return ShockDecoStylePrivate::Load(
		TEXT("/Game/BioShockUI/Deco/T_Deco_Scrollbar.T_Deco_Scrollbar"));
}

UTexture2D* UShockDecoStyle::LoadChevron()
{
	return ShockDecoStylePrivate::Load(
		TEXT("/Game/BioShockUI/Pause/T_Pause_ChevronUp.T_Pause_ChevronUp"));
}

FSlateBrush UShockDecoStyle::MakeBoxBrush(
	UTexture2D* Texture,
	const FMargin& Margin,
	FVector2D ImageSize,
	FLinearColor Tint)
{
	FSlateBrush Brush;
	Brush.DrawAs = ESlateBrushDrawType::Box;
	Brush.Tiling = ESlateBrushTileType::NoTile;
	Brush.Margin = Margin;
	Brush.ImageSize = ImageSize;
	Brush.TintColor = FSlateColor(Tint);
	if (Texture)
	{
		Brush.SetResourceObject(Texture);
	}
	return Brush;
}

FSlateBrush UShockDecoStyle::MakeListButtonBrush(bool bHovered, FVector2D Size)
{
	return MakeBoxBrush(LoadListButton(bHovered), ListButtonMargin(), Size);
}

FSlateBrush UShockDecoStyle::MakePanelFrameBrush(FVector2D Size)
{
	return MakeBoxBrush(LoadPanelFrame(), PanelFrameMargin(), Size);
}

FSlateBrush UShockDecoStyle::MakePanelFillBrush(FVector2D Size)
{
	UTexture2D* Fill = LoadPanelFill();
	FSlateBrush Brush = ShockDecoStylePrivate::MakeImage(
		Fill, Size, FLinearColor(0.08f, 0.07f, 0.06f, 0.92f));
	if (Fill)
	{
		Brush.Tiling = ESlateBrushTileType::Both;
		Brush.DrawAs = ESlateBrushDrawType::Image;
	}
	return Brush;
}

FSlateBrush UShockDecoStyle::MakeBannerBrush(FVector2D Size)
{
	return MakeBoxBrush(LoadBanner(), BannerMargin(), Size);
}

FSlateBrush UShockDecoStyle::MakeNameplateBrush(bool bWide, FVector2D Size)
{
	return MakeBoxBrush(LoadNameplate(bWide), NameplateMargin(), Size);
}

FSlateBrush UShockDecoStyle::MakeRowPlateBrush(FVector2D Size)
{
	return MakeBoxBrush(LoadRowPlate(false), RowPlateMargin(), Size);
}

FSlateBrush UShockDecoStyle::MakeSlotGridBrush(FVector2D Size)
{
	return ShockDecoStylePrivate::MakeImage(LoadSlotGrid(), Size, FLinearColor::White);
}

FSlateBrush UShockDecoStyle::MakeVignetteBrush()
{
	UTexture2D* Fill = LoadPanelFill();
	FSlateBrush Brush = ShockDecoStylePrivate::MakeImage(
		Fill, FVector2D(64.0f, 64.0f), FLinearColor(0.04f, 0.05f, 0.06f, 1.0f));
	Brush.Tiling = ESlateBrushTileType::Both;
	return Brush;
}

void UShockDecoStyle::ApplyListButtonStyle(UButton* Button, bool bSelected)
{
	if (!Button)
	{
		return;
	}
	UTexture2D* NormalTex = LoadListButton(false);
	UTexture2D* HoverTex = LoadListButton(true);
	if (!NormalTex)
	{
		return;
	}
	const FVector2D Size(420.0f, 48.0f);
	FButtonStyle Style = Button->GetStyle();
	Style.SetNormal(MakeBoxBrush(NormalTex, ListButtonMargin(), Size));
	Style.SetHovered(MakeBoxBrush(HoverTex ? HoverTex : NormalTex, ListButtonMargin(), Size));
	Style.SetPressed(MakeBoxBrush(HoverTex ? HoverTex : NormalTex, ListButtonMargin(), Size));
	if (bSelected && HoverTex)
	{
		Style.SetNormal(MakeBoxBrush(HoverTex, ListButtonMargin(), Size));
	}
	Style.NormalPadding = FMargin(20.0f, 10.0f);
	Style.PressedPadding = FMargin(20.0f, 10.0f);
	Button->SetStyle(Style);
	Button->SetBackgroundColor(FLinearColor(1.0f, 1.0f, 1.0f, 1.0f));
}

void UShockDecoStyle::ApplyImageBrush(UImage* Image, const FSlateBrush& Brush)
{
	if (!Image)
	{
		return;
	}
	Image->SetBrush(Brush);
	Image->SetDesiredSizeOverride(Brush.ImageSize);
}

void UShockDecoStyle::ApplyBanner(UImage* Image, FVector2D Size)
{
	ApplyImageBrush(Image, MakeBannerBrush(Size));
}

void UShockDecoStyle::ApplyNameplate(UImage* Image, bool bWide, FVector2D Size)
{
	ApplyImageBrush(Image, MakeNameplateBrush(bWide, Size));
}

void UShockDecoStyle::ApplyPanelFrame(UImage* Image, FVector2D Size)
{
	ApplyImageBrush(Image, MakePanelFrameBrush(Size));
}

void UShockDecoStyle::ApplyRowPlate(UImage* Image, FVector2D Size)
{
	ApplyImageBrush(Image, MakeRowPlateBrush(Size));
}

void UShockDecoStyle::ApplySlotGrid(UImage* Image, FVector2D Size)
{
	ApplyImageBrush(Image, MakeSlotGridBrush(Size));
}

void UShockDecoStyle::ApplyVignetteBackground(UBorder* Border)
{
	if (!Border)
	{
		return;
	}
	if (UTexture2D* Fill = LoadPanelFill())
	{
		Border->SetBrush(MakeVignetteBrush());
	}
	else
	{
		Border->SetBrushColor(FLinearColor(0.04f, 0.05f, 0.06f, 1.0f));
	}
}

bool UShockDecoStyle::HasRequiredTextures()
{
	return LoadListButton(false) != nullptr && LoadPanelFrame() != nullptr
		&& LoadBanner() != nullptr && LoadRowPlate(false) != nullptr;
}
