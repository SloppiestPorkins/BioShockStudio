#pragma once

#include "Blueprint/UserWidget.h"
#include "ShockHudWidget.generated.h"

class AShockPlayer;
class AShockWeapon;
class UBorder;
class UProgressBar;
class UTextBlock;

/** Minimal in-game HUD: health (bottom-left) + weapon ammo (bottom-right). C++ tree, no designer asset. */
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
	bool IsAmmoPanelVisible() const { return bAmmoPanelVisible; }

	/** Editor/headless: spawn player+weapon, create HUD, assert text + viewport, damage + re-assert. */
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
	void RefreshDisplay();
	AShockPlayer* ResolvePlayer() const;
	AShockWeapon* ResolveEquippedWeapon(AShockPlayer* Player) const;
	void SetHealthTextColor(const FLinearColor& Color);

	void EnsureRefreshTimer();

	UPROPERTY(Transient)
	TObjectPtr<UTextBlock> HealthText = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UProgressBar> HealthBar = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTextBlock> EveText = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTextBlock> PlasmidText = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UProgressBar> EveBar = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTextBlock> AmmoMagText = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTextBlock> AmmoWeaponNameText = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTextBlock> AmmoReserveText = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UBorder> AmmoPanel = nullptr;

	FString CachedHealthText;
	FString CachedEveText;
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
