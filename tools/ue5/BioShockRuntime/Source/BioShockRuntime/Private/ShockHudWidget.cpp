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
constexpr float MeterImageWidth = 220.0f;
constexpr float MeterImageHeight = 88.0f;

const TCHAR* HealthArcTexturePath = TEXT("/Game/BioShockUI/HUD/T_Hud_HealthArc.T_Hud_HealthArc");
const TCHAR* EveArcTexturePath = TEXT("/Game/BioShockUI/HUD/T_Hud_EveArc.T_Hud_EveArc");
const TCHAR* MeterUnderlayTexturePath =
	TEXT("/Game/BioShockUI/HUD/T_Hud_MeterUnderlay.T_Hud_MeterUnderlay");

FLinearColor HudGold() { return FLinearColor(0.92f, 0.78f, 0.35f, 1.0f); }
FLinearColor HudWhite() { return FLinearColor(0.95f, 0.95f, 0.95f, 1.0f); }
FLinearColor HudRed() { return FLinearColor(0.95f, 0.15f, 0.12f, 1.0f); }

FSlateFontInfo MakeHudFont(int32 Size, bool bBold = false)
{
	return FCoreStyle::GetDefaultFontStyle(bBold ? TEXT("Bold") : TEXT("Regular"), Size);
}

UBorder* MakeHudBacking(UWidgetTree* Tree, FName Name)
{
	UBorder* Border = Tree->ConstructWidget<UBorder>(UBorder::StaticClass(), Name);
	Border->SetBrushColor(FLinearColor(0.0f, 0.0f, 0.0f, 0.45f));
	Border->SetPadding(FMargin(10.0f, 8.0f));
	return Border;
}

UCanvasPanelSlot* AnchorBottomCorner(UCanvasPanel* Canvas, UWidget* Child, bool bRight)
{
	UCanvasPanelSlot* Slot = Canvas->AddChildToCanvas(Child);
	Slot->SetAnchors(FAnchors(bRight ? 1.0f : 0.0f, 1.0f, bRight ? 1.0f : 0.0f, 1.0f));
	Slot->SetAlignment(FVector2D(bRight ? 1.0f : 0.0f, 1.0f));
	Slot->SetAutoSize(true);
	Slot->SetPosition(FVector2D(bRight ? -24.0f : 24.0f, -24.0f));
	return Slot;
}

UImage* MakeMeterImage(UWidgetTree* Tree, FName Name)
{
	UImage* Image = Tree->ConstructWidget<UImage>(UImage::StaticClass(), Name);
	Image->SetBrushSize(FVector2D(MeterImageWidth, MeterImageHeight));
	Image->SetVisibility(ESlateVisibility::HitTestInvisible);
	return Image;
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

	UBorder* HealthBacking = MakeHudBacking(WidgetTree, TEXT("HealthBacking"));
	UVerticalBox* HealthBox = WidgetTree->ConstructWidget<UVerticalBox>(
		UVerticalBox::StaticClass(), TEXT("HealthBox"));
	HealthBacking->SetContent(HealthBox);

	UOverlay* HealthMeterOverlay = WidgetTree->ConstructWidget<UOverlay>(
		UOverlay::StaticClass(), TEXT("HealthMeterOverlay"));
	MeterUnderlayImage = MakeMeterImage(WidgetTree, TEXT("MeterUnderlayImage"));
	if (UOverlaySlot* UnderlaySlot = HealthMeterOverlay->AddChildToOverlay(MeterUnderlayImage))
	{
		UnderlaySlot->SetHorizontalAlignment(HAlign_Left);
		UnderlaySlot->SetVerticalAlignment(VAlign_Bottom);
	}
	HealthArcImage = MakeMeterImage(WidgetTree, TEXT("HealthArcImage"));
	if (UOverlaySlot* HealthArcSlot = HealthMeterOverlay->AddChildToOverlay(HealthArcImage))
	{
		HealthArcSlot->SetHorizontalAlignment(HAlign_Left);
		HealthArcSlot->SetVerticalAlignment(VAlign_Bottom);
	}
	if (UVerticalBoxSlot* MeterSlot = HealthBox->AddChildToVerticalBox(HealthMeterOverlay))
	{
		MeterSlot->SetPadding(FMargin(0.0f, 0.0f, 0.0f, 4.0f));
	}

	HealthText = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("HealthText"));
	HealthText->SetText(FText::FromString(TEXT("--")));
	HealthText->SetFont(MakeHudFont(28, true));
	HealthText->SetColorAndOpacity(FSlateColor(HudWhite()));
	if (UVerticalBoxSlot* HealthTextSlot = HealthBox->AddChildToVerticalBox(HealthText))
	{
		HealthTextSlot->SetPadding(FMargin(0.0f, 0.0f, 0.0f, 4.0f));
	}

	EveArcImage = MakeMeterImage(WidgetTree, TEXT("EveArcImage"));
	if (UVerticalBoxSlot* EveArcSlot = HealthBox->AddChildToVerticalBox(EveArcImage))
	{
		EveArcSlot->SetPadding(FMargin(0.0f, 4.0f, 0.0f, 2.0f));
	}

	EveText = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("EveText"));
	EveText->SetText(FText::FromString(TEXT("EVE --")));
	EveText->SetFont(MakeHudFont(18, true));
	EveText->SetColorAndOpacity(FSlateColor(FLinearColor(0.55f, 0.85f, 1.0f, 1.0f)));
	if (UVerticalBoxSlot* EveTextSlot = HealthBox->AddChildToVerticalBox(EveText))
	{
		EveTextSlot->SetPadding(FMargin(0.0f, 0.0f, 0.0f, 2.0f));
	}

	ConsumablesText = WidgetTree->ConstructWidget<UTextBlock>(
		UTextBlock::StaticClass(), TEXT("ConsumablesText"));
	ConsumablesText->SetText(FText::FromString(TEXT("")));
	ConsumablesText->SetFont(MakeHudFont(13));
	ConsumablesText->SetColorAndOpacity(FSlateColor(FLinearColor(0.85f, 0.9f, 0.85f, 1.0f)));
	if (UVerticalBoxSlot* ConsumablesSlot = HealthBox->AddChildToVerticalBox(ConsumablesText))
	{
		ConsumablesSlot->SetPadding(FMargin(0.0f, 0.0f, 0.0f, 2.0f));
	}

	PlasmidText = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("PlasmidText"));
	PlasmidText->SetText(FText::FromString(TEXT("")));
	PlasmidText->SetFont(MakeHudFont(14));
	PlasmidText->SetColorAndOpacity(FSlateColor(FLinearColor(1.0f, 0.72f, 0.35f, 1.0f)));
	if (UVerticalBoxSlot* PlasmidTextSlot = HealthBox->AddChildToVerticalBox(PlasmidText))
	{
		PlasmidTextSlot->SetPadding(FMargin(0.0f, 0.0f, 0.0f, 2.0f));
	}

	EnsureHudTextures();
	AnchorBottomCorner(Canvas, HealthBacking, false);

	AmmoPanel = MakeHudBacking(WidgetTree, TEXT("AmmoBacking"));
	UVerticalBox* AmmoBox = WidgetTree->ConstructWidget<UVerticalBox>(
		UVerticalBox::StaticClass(), TEXT("AmmoBox"));
	AmmoPanel->SetContent(AmmoBox);

	AmmoWeaponNameText = WidgetTree->ConstructWidget<UTextBlock>(
		UTextBlock::StaticClass(), TEXT("AmmoWeaponNameText"));
	AmmoWeaponNameText->SetText(FText::FromString(TEXT("")));
	AmmoWeaponNameText->SetJustification(ETextJustify::Right);
	AmmoWeaponNameText->SetFont(MakeHudFont(14, true));
	AmmoWeaponNameText->SetColorAndOpacity(FSlateColor(HudWhite()));
	if (UVerticalBoxSlot* NameSlot = AmmoBox->AddChildToVerticalBox(AmmoWeaponNameText))
	{
		NameSlot->SetHorizontalAlignment(HAlign_Right);
		NameSlot->SetPadding(FMargin(0.0f, 0.0f, 0.0f, 4.0f));
	}

	AmmoMagText = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("AmmoMagText"));
	AmmoMagText->SetText(FText::FromString(TEXT("--")));
	AmmoMagText->SetJustification(ETextJustify::Right);
	AmmoMagText->SetFont(MakeHudFont(32, true));
	AmmoMagText->SetColorAndOpacity(FSlateColor(HudGold()));
	if (UVerticalBoxSlot* MagSlot = AmmoBox->AddChildToVerticalBox(AmmoMagText))
	{
		MagSlot->SetHorizontalAlignment(HAlign_Right);
	}

	AmmoReserveText = WidgetTree->ConstructWidget<UTextBlock>(
		UTextBlock::StaticClass(), TEXT("AmmoReserveText"));
	AmmoReserveText->SetText(FText::FromString(TEXT("")));
	AmmoReserveText->SetJustification(ETextJustify::Right);
	AmmoReserveText->SetFont(MakeHudFont(18));
	AmmoReserveText->SetColorAndOpacity(FSlateColor(HudWhite()));
	if (UVerticalBoxSlot* ReserveSlot = AmmoBox->AddChildToVerticalBox(AmmoReserveText))
	{
		ReserveSlot->SetHorizontalAlignment(HAlign_Right);
		ReserveSlot->SetPadding(FMargin(0.0f, 2.0f, 0.0f, 0.0f));
	}

	AnchorBottomCorner(Canvas, AmmoPanel, true);
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

void UShockHudWidget::SetHealthTextColor(const FLinearColor& Color)
{
	if (HealthText)
	{
		HealthText->SetColorAndOpacity(FSlateColor(Color));
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
	Image->SetColorAndOpacity(FLinearColor(1.0f, 1.0f, 1.0f, Alpha));
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
		SetHealthTextColor(HudWhite());
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
		SetHealthTextColor(HudRed());
	}
	else if (DamageFlashEndTime < 0.0)
	{
		SetHealthTextColor(HudWhite());
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
		return;
	}

	const int32 Mag = Weapon->GetRoundsInMagazine();
	const int32 Reserve = Weapon->GetReserveAmmo();
	CachedWeaponNameText = Weapon->GetWeaponDefName().IsNone() ? TEXT("") : Weapon->GetWeaponDefName().ToString();
	CachedAmmoMagText = FString::FromInt(Mag);
	CachedAmmoReserveText = FString::Printf(TEXT("/ %d"), Reserve);
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
			 "health_tex=%d eve_tex=%d"),
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
