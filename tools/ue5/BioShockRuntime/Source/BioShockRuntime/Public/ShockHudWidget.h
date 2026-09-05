#pragma once

#include "Blueprint/UserWidget.h"
#include "ShockHudWidget.generated.h"

class AShockPlayer;
class AShockWeapon;
class UBorder;
class UImage;
class UTextBlock;

/**
 * In-game HUD arranged like BioShock 1 PC: bottom-left health/EVE arcs, plasmid ring,
 * weapon/ammo cluster; top-left objective; center crosshair. Arc textures from decoded
 * Scaleform art; missing frame/cap/icon bitmaps use UMG Deco stand-ins (tag-512 blocker).
 */
UCLASS()
class BIOSHOCKRUNTIME_API UShockHudWidget : public UUserWidget
{
	GENERATED_BODY()

public:
	UShockHudWidget(const FObjectInitializer& ObjectInitializer);

	UFUNCTION(BlueprintCallable, Category="BioShock|HUD")
	void RefreshDisplayNow();

	/** When the widget has no possessed pawn (headless verify), read stats from this player. */
	UFUNCTION(BlueprintCallable, Category="BioShock|HUD")
	void BindDisplayPlayer(AShockPlayer* Player);

	UFUNCTION(BlueprintPure, Category="BioShock|HUD")
	FString GetDisplayedHealthText() const;

	UFUNCTION(BlueprintPure, Category="BioShock|HUD")
	FString GetDisplayedAmmoMagText() const;

	UFUNCTION(BlueprintPure, Category="BioShock|HUD")
	FString GetDisplayedWeaponNameText() const;

	UFUNCTION(BlueprintPure, Category="BioShock|HUD")
	FString GetDisplayedAmmoReserveText() const;

	UFUNCTION(BlueprintPure, Category="BioShock|HUD")
	FString GetDisplayedEveText() const;

	UFUNCTION(BlueprintPure, Category="BioShock|HUD")
	FString GetDisplayedConsumablesText() const;

	UFUNCTION(BlueprintPure, Category="BioShock|HUD")
	bool IsAmmoPanelVisible() const { return bAmmoPanelVisible; }

	/** True when the health-arc UImage has a non-null Texture2D brush (after import_hud_ui). */
	UFUNCTION(BlueprintPure, Category="BioShock|HUD")
	bool HasHealthArcTexture() const;

	/** True when the EVE-arc UImage has a non-null Texture2D brush (after import_hud_ui). */
	UFUNCTION(BlueprintPure, Category="BioShock|HUD")
	bool HasEveArcTexture() const;

	/** Editor/headless: spawn player+weapon, create HUD, assert text + textures + viewport, damage + re-assert. */
	UFUNCTION(BlueprintCallable, Category="BioShock|HUD")
	static bool RunHeadlessHudVerify(UObject* WorldContextObject);

	UFUNCTION(BlueprintPure, Category="BioShock|HUD")
	static FString GetLastHudVerifyError();

protected:
	virtual TSharedRef<SWidget> RebuildWidget() override;
	virtual void NativeConstruct() override;
	virtual void NativeDestruct() override;

private:
	void EnsureWidgetTree();
	void EnsureHudTextures();
	void RefreshDisplay();
	AShockPlayer* ResolvePlayer() const;
	AShockWeapon* ResolveEquippedWeapon(AShockPlayer* Player) const;
	void ApplyDamageFlashVisual(bool bFlashing);
	void SetMeterImageOpacity(UImage* Image, float Percent) const;

	void EnsureRefreshTimer();

	UPROPERTY(Transient)
	TObjectPtr<UImage> MeterUnderlayImage = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UImage> HealthArcImage = nullptr;

	/** Cached for GetDisplayedHealthText / damage verify — not shown as a large on-bar numeral. */
	UPROPERTY(Transient)
	TObjectPtr<UTextBlock> HealthText = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UImage> EveArcImage = nullptr;

	/** Cached for GetDisplayedEveText — EVE amount is read from the meter, not a bar numeral. */
	UPROPERTY(Transient)
	TObjectPtr<UTextBlock> EveText = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTextBlock> ConsumablesText = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTextBlock> PlasmidText = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTextBlock> EveCostText = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UBorder> PlasmidRing = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UImage> PlasmidIconImage = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UBorder> HealthCapSlot = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UBorder> EveCapSlot = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UImage> WeaponIconImage = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTextBlock> AmmoMagText = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTextBlock> AmmoWeaponNameText = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTextBlock> AmmoReserveText = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTextBlock> AmmoTypeText = nullptr;

	/** Weapon/ammo cluster root — visibility gated by bEnforceAmmo (no black backing). */
	UPROPERTY(Transient)
	TObjectPtr<UBorder> AmmoPanel = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTextBlock> ObjectiveText = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTextBlock> CrosshairText = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTexture2D> HealthArcTexture = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTexture2D> EveArcTexture = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTexture2D> MeterUnderlayTexture = nullptr;

	FString CachedHealthText;
	FString CachedEveText;
	FString CachedConsumablesText;
	FString CachedPlasmidText;
	FString CachedAmmoMagText;
	FString CachedWeaponNameText;
	FString CachedAmmoReserveText;
	bool bAmmoPanelVisible = false;

	float LastObservedHealth = -1.0f;
	float DamageFlashEndTime = -1.0f;

	UPROPERTY(Transient)
	TWeakObjectPtr<AShockPlayer> DisplayPlayerOverride;

	FTimerHandle RefreshTimerHandle;

	static FString LastHudVerifyError;
};
