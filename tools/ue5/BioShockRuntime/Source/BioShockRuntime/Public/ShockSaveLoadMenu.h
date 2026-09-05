#pragma once

#include "Blueprint/UserWidget.h"
#include "ShockSaveLoadMenu.generated.h"

class AShockPlayer;
class UBorder;
class UButton;
class UHorizontalBox;
class UImage;
class UOverlay;
class UScrollBox;
class UTextBlock;
class UVerticalBox;
class UShockSaveGame;
class UShockSaveLoadMenu;
class UShockCarryState;

UENUM(BlueprintType)
enum class EShockSaveLoadMode : uint8
{
	Save,
	Load,
};

UCLASS()
class BIOSHOCKRUNTIME_API UShockSaveLoadSlotRow : public UUserWidget
{
	GENERATED_BODY()

public:
	void Configure(
		UShockSaveLoadMenu* InOwner,
		int32 InSlotIndex,
		const FString& Title,
		const FString& Subtitle,
		bool bEmpty,
		bool bSelected);

protected:
	virtual TSharedRef<SWidget> RebuildWidget() override;

	UFUNCTION()
	void HandleClicked();

	UPROPERTY(Transient)
	TObjectPtr<UButton> RowButton = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UOverlay> RowOverlay = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UImage> PlateImage = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UHorizontalBox> RowBox = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UBorder> ThumbBox = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTextBlock> TitleText = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTextBlock> SubText = nullptr;

	UPROPERTY(Transient)
	TWeakObjectPtr<UShockSaveLoadMenu> OwnerMenu;

	int32 SlotIndex = 0;
	FString PendingTitle;
	FString PendingSub;
	bool bPendingEmpty = true;
	bool bPendingSelected = false;
};

/**
 * Save / Load slot list: timestamp + level name + thumbnail placeholder.
 * Uses UShockSaveGame via SaveGameToSlot / LoadGameFromSlot.
 */
UCLASS()
class BIOSHOCKRUNTIME_API UShockSaveLoadMenu : public UUserWidget
{
	GENERATED_BODY()

public:
	UShockSaveLoadMenu(const FObjectInitializer& ObjectInitializer);

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Save")
	void OpenSaveLoad(EShockSaveLoadMode Mode);

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Save")
	void CloseSaveLoad();

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Save")
	EShockSaveLoadMode GetMode() const { return Mode; }

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Save")
	bool IsOpen() const { return bOpen; }

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Save")
	void BindDisplayPlayer(AShockPlayer* Player);

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Save")
	void SetSelectedSlot(int32 Index);

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Save")
	bool ActivateSelectedSlot();

	void HandleSlotClicked(int32 Index);

	/** Save current carry (or BoundPlayer capture) into slot. */
	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Save")
	bool SaveToSlot(int32 SlotIndex, UShockCarryState* CarryOverride = nullptr);

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Save")
	UShockSaveGame* LoadFromSlot(int32 SlotIndex) const;

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Save")
	static bool RunHeadlessSaveLoadVerify(UObject* WorldContextObject);

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Save")
	static FString GetLastSaveLoadVerifyError();

protected:
	virtual TSharedRef<SWidget> RebuildWidget() override;
	virtual void NativeConstruct() override;
	virtual FReply NativeOnKeyDown(const FGeometry& InGeometry, const FKeyEvent& InKeyEvent) override;

private:
	void EnsureWidgetTree();
	void RefreshSlotList();
	FString ResolveCurrentLevelPath() const;
	FString PrettyLevelName(const FString& PackagePath) const;
	AShockPlayer* ResolvePlayer() const;

	UPROPERTY(Transient)
	TObjectPtr<UVerticalBox> RootColumn = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UImage> HeaderBanner = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTextBlock> HeaderText = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UScrollBox> SlotScroll = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UVerticalBox> SlotList = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UButton> BackButton = nullptr;

	UPROPERTY(Transient)
	TWeakObjectPtr<AShockPlayer> DisplayPlayerOverride;

	EShockSaveLoadMode Mode = EShockSaveLoadMode::Load;
	int32 SelectedSlot = 0;
	bool bOpen = false;

	static FString LastVerifyError;

	UFUNCTION()
	void OnBackClicked();
};
