#pragma once

#include "Blueprint/UserWidget.h"
#include "ShockHudWidget.generated.h"

class AShockPlayer;
class AShockWeapon;
class UBorder;
class UHorizontalBox;
class UImage;
class UMaterialInstanceDynamic;
class UOverlay;
class UProgressBar;
class USizeBox;
class UTextBlock;
class UVerticalBox;

/** In-game HUD: upper-left health/EVE meters from real Scaleform art + weapon/plasmid clusters. */
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

	/** True when the lower-right weapon cluster (ring + name) is shown. */
	UFUNCTION(BlueprintPure, Category="BioShock|HUD")
	bool IsAmmoPanelVisible() const { return bAmmoPanelVisible; }

	/** True when magazine/reserve digit rows are shown (bEnforceAmmo weapons only). */
	UFUNCTION(BlueprintPure, Category="BioShock|HUD")
	bool IsAmmoDigitsVisible() const { return bAmmoDigitsVisible; }

	/** True when the health meter frame UImage has a non-null Texture2D brush (after import_bioshock_ui). */
	UFUNCTION(BlueprintPure, Category="BioShock|HUD")
	bool HasHealthMeterFrame() const;

	/** True when the EVE meter frame UImage has a non-null Texture2D brush. */
	UFUNCTION(BlueprintPure, Category="BioShock|HUD")
	bool HasEveMeterFrame() const;

	/** True when at least one HUD digit glyph texture resolved. */
	UFUNCTION(BlueprintPure, Category="BioShock|HUD")
	bool HasDigitTextures() const;

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
	void SetMeterFill(UProgressBar* FillBar, UMaterialInstanceDynamic* FillMID, float Percent, const FLinearColor& Tint) const;
	void SetDigitString(UHorizontalBox* Box, const TArray<TObjectPtr<UImage>>& Slots, const FString& Digits, float Scale) const;
	void SetCountDigits(UHorizontalBox* Box, const TArray<TObjectPtr<UImage>>& Slots, int32 Count) const;
	void ApplyDamageFlashVisuals(bool bLeft, bool bRight, bool bTop, bool bBottom);
	void FlashDamageFromHit(AShockPlayer* Player);
	void EnsureRefreshTimer();
	UMaterialInstanceDynamic* EnsureFillMID(TObjectPtr<UMaterialInstanceDynamic>& MidSlot, FName DebugName);

	UPROPERTY(Transient)
	TObjectPtr<UImage> HealthMeterFrame = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UProgressBar> HealthFillBar = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UImage> HealthFillHighlight = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UImage> HealthCapIcon = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UHorizontalBox> KitCountDigits = nullptr;

	UPROPERTY(Transient)
	TArray<TObjectPtr<UImage>> KitCountDigitImages;

	UPROPERTY(Transient)
	TObjectPtr<UImage> EveMeterFrame = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UProgressBar> EveFillBar = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UImage> EveFillHighlight = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UImage> EveCapIcon = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UHorizontalBox> HypoCountDigits = nullptr;

	UPROPERTY(Transient)
	TArray<TObjectPtr<UImage>> HypoCountDigitImages;

	UPROPERTY(Transient)
	TObjectPtr<UTextBlock> ToastText = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UImage> CrosshairImage = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UImage> VignetteImage = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UBorder> DamageFlashLeft = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UBorder> DamageFlashRight = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UBorder> DamageFlashTop = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UBorder> DamageFlashBottom = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UImage> PlasmidRingImage = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTextBlock> PlasmidText = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UBorder> AmmoPanel = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UImage> WeaponRingImage = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTextBlock> AmmoWeaponNameText = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UHorizontalBox> AmmoMagDigits = nullptr;

	UPROPERTY(Transient)
	TArray<TObjectPtr<UImage>> AmmoMagDigitImages;

	UPROPERTY(Transient)
	TObjectPtr<UHorizontalBox> AmmoReserveDigits = nullptr;

	UPROPERTY(Transient)
	TArray<TObjectPtr<UImage>> AmmoReserveDigitImages;

	UPROPERTY(Transient)
	TObjectPtr<UVerticalBox> AmmoDigitsColumn = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTexture2D> MeterFrameTexture = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTexture2D> FillMaskTexture = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UMaterialInterface> LiquidFillMaterial = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UMaterialInstanceDynamic> HealthFillMID = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UMaterialInstanceDynamic> EveFillMID = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTexture2D> BrassRingTexture = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTexture2D> VignetteTexture = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTexture2D> CrossIconTexture = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTexture2D> HypoIconTexture = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTexture2D> DigitTextures[10];

	FString CachedHealthText;
	FString CachedEveText;
	FString CachedConsumablesText;
	FString CachedPlasmidText;
	FString CachedAmmoMagText;
	FString CachedWeaponNameText;
	FString CachedAmmoReserveText;
	bool bAmmoPanelVisible = false;
	bool bAmmoDigitsVisible = false;

	float LastObservedHealth = -1.0f;
	// Smoothly-animated fill fractions (-1 = uninitialised, snap on first frame).
	float DisplayedHealthPct = -1.0f;
	float DisplayedEvePct = -1.0f;
	float DamageFlashEndTime = -1.0f;
	bool bDamageFlashLeft = false;
	bool bDamageFlashRight = false;
	bool bDamageFlashTop = false;
	bool bDamageFlashBottom = false;

	UPROPERTY(Transient)
	TWeakObjectPtr<AShockPlayer> DisplayPlayerOverride;

	FTimerHandle RefreshTimerHandle;

	static FString LastHudVerifyError;
};
