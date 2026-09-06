#pragma once

#include "Blueprint/UserWidget.h"
#include "ShockRadialMenu.generated.h"

class AShockPlayer;
class AShockWeapon;
class UBorder;
class UCanvasPanel;
class UHorizontalBox;
class UImage;
class UShockPlasmid;
class UTextBlock;

UENUM(BlueprintType)
enum class EShockRadialMode : uint8
{
	Weapon UMETA(DisplayName = "Weapon"),
	Plasmid UMETA(DisplayName = "Plasmid"),
};

/** Hold-to-open brass radial for weapons or plasmids (HUDRadial.swf stand-in). */
UCLASS()
class BIOSHOCKRUNTIME_API UShockRadialMenu : public UUserWidget
{
	GENERATED_BODY()

public:
	UShockRadialMenu(const FObjectInitializer& ObjectInitializer);

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Radial")
	void BindDisplayPlayer(AShockPlayer* Player);

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Radial")
	void OpenRadial(EShockRadialMode Mode);

	/** Close the wheel. When bEquipHovered, SelectWeaponSlot / SelectPlasmidSlot on the hover. */
	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Radial")
	void CloseRadial(bool bEquipHovered);

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Radial")
	void ForceOpenForCapture(EShockRadialMode Mode);

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Radial")
	bool IsRadialOpen() const { return bOpen; }

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Radial")
	EShockRadialMode GetRadialMode() const { return Mode; }

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Radial")
	int32 GetSegmentCount() const { return SegmentSlotIndices.Num(); }

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Radial")
	int32 GetHoveredSegmentIndex() const { return HoveredSegment; }

	/** Absolute weapon/plasmid slot for HoveredSegment, or -1. */
	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Radial")
	int32 GetHoveredSlotIndex() const;

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Radial")
	void SetHoveredSegmentIndex(int32 SegmentIndex);

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Radial")
	void StepHoveredSegment(int32 Delta);

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Radial")
	bool HasRingTexture() const;

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Radial")
	bool HasDigitTextures() const;

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Radial")
	FString GetCenterNameText() const { return CachedCenterName; }

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Radial")
	FString GetCenterStatText() const { return CachedCenterStat; }

	/** Editor/headless: N weapons → N segments; release equips SelectWeaponSlot; plasmids listed. */
	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Radial")
	static bool RunHeadlessRadialVerify(UObject* WorldContextObject);

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Radial")
	static FString GetLastRadialVerifyError();

protected:
	virtual TSharedRef<SWidget> RebuildWidget() override;
	virtual void NativeConstruct() override;
	virtual void NativeDestruct() override;
	virtual void NativeTick(const FGeometry& MyGeometry, float InDeltaTime) override;

private:
	void EnsureWidgetTree();
	void EnsureTextures();
	void RebuildSegments();
	void RefreshCenterReadout();
	void UpdateHoverFromMouse();
	void ApplySegmentVisuals();
	AShockPlayer* ResolvePlayer() const;
	void SetDigitString(UHorizontalBox* Box, const TArray<TObjectPtr<UImage>>& Slots, const FString& Digits) const;

	UPROPERTY(Transient)
	TObjectPtr<UCanvasPanel> RootCanvas = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UBorder> DimOverlay = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UImage> RingImage = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTextBlock> CenterNameText = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTextBlock> SelectPromptText = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UHorizontalBox> CenterStatDigits = nullptr;

	UPROPERTY(Transient)
	TArray<TObjectPtr<UImage>> CenterStatDigitImages;

	UPROPERTY(Transient)
	TArray<TObjectPtr<UTextBlock>> SegmentLabels;

	UPROPERTY(Transient)
	TArray<TObjectPtr<UImage>> SegmentRings;

	UPROPERTY(Transient)
	TObjectPtr<UTexture2D> RingTexture = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTexture2D> DigitTextures[10];

	UPROPERTY(Transient)
	TWeakObjectPtr<AShockPlayer> DisplayPlayerOverride;

	TArray<int32> SegmentSlotIndices;
	EShockRadialMode Mode = EShockRadialMode::Weapon;
	int32 HoveredSegment = 0;
	bool bOpen = false;
	FString CachedCenterName;
	FString CachedCenterStat;

	static FString LastRadialVerifyError;
};
