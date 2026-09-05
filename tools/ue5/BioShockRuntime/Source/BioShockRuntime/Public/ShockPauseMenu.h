#pragma once

#include "Blueprint/UserWidget.h"
#include "ShockPauseMenu.generated.h"

class AShockPlayer;
class UButton;
class UHorizontalBox;
class UImage;
class UTextBlock;
class UVerticalBox;
class UShockPauseMenu;

/** One selectable row in the pause list (Resume / Save / …). */
UCLASS()
class BIOSHOCKRUNTIME_API UShockPauseMenuRow : public UUserWidget
{
	GENERATED_BODY()

public:
	void Configure(
		UShockPauseMenu* InOwner,
		int32 InRowIndex,
		const FString& Label,
		bool bSelected,
		UTexture2D* ChevronTex = nullptr);

protected:
	virtual TSharedRef<SWidget> RebuildWidget() override;

	UFUNCTION()
	void HandleClicked();

	UPROPERTY(Transient)
	TObjectPtr<UButton> RowButton = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UHorizontalBox> RowBox = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UImage> Chevron = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTextBlock> RowText = nullptr;

	UPROPERTY(Transient)
	TWeakObjectPtr<UShockPauseMenu> OwnerMenu;

	int32 RowIndex = 0;
	FString PendingLabel;
	bool bPendingSelected = false;
	TWeakObjectPtr<UTexture2D> PendingChevron;
};

/**
 * Pause overlay (pausePC.swf stand-in): logo, Money/ADAM/Little-Sister stats,
 * Resume / Save / Load / Options / Main Menu / Quit.
 */
UCLASS()
class BIOSHOCKRUNTIME_API UShockPauseMenu : public UUserWidget
{
	GENERATED_BODY()

public:
	UShockPauseMenu(const FObjectInitializer& ObjectInitializer);

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Pause")
	void BindDisplayPlayer(AShockPlayer* Player);

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Pause")
	void OpenPauseMenu();

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Pause")
	void ClosePauseMenu();

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Pause")
	void ForceOpenForCapture();

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Pause")
	bool IsPauseOpen() const { return bOpen; }

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Pause")
	void SetSelectedIndex(int32 Index);

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Pause")
	void StepSelection(int32 Delta);

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Pause")
	int32 GetSelectedIndex() const { return SelectedIndex; }

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Pause")
	int32 GetDisplayedMoney() const { return CachedMoney; }

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Pause")
	int32 GetDisplayedAdam() const { return CachedAdam; }

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Pause")
	int32 GetDisplayedLittleSisterCount() const { return CachedLittleSisters; }

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Pause")
	bool HasRequiredTextures() const;

	void HandleRowClicked(int32 Index);

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Pause")
	static bool RunHeadlessPauseVerify(UObject* WorldContextObject);

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Pause")
	static FString GetLastPauseVerifyError();

	/** Count actors whose class name contains Gatherer or LittleSister (no dedicated class yet). */
	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Pause", meta = (WorldContext = "WorldContextObject"))
	static int32 CountLittleSisterActors(UObject* WorldContextObject);

protected:
	virtual TSharedRef<SWidget> RebuildWidget() override;
	virtual void NativeConstruct() override;
	virtual FReply NativeOnKeyDown(const FGeometry& InGeometry, const FKeyEvent& InKeyEvent) override;

private:
	enum class EPauseAction : uint8
	{
		Resume = 0,
		Save,
		Load,
		Options,
		MainMenu,
		Quit,
		Count
	};

	void EnsureWidgetTree();
	void EnsureTextures();
	void RefreshStats();
	void RebuildList();
	void ActivateSelected();
	void ActivateAction(EPauseAction Action);
	AShockPlayer* ResolvePlayer() const;
	void SetPaused(bool bPause);

	UPROPERTY(Transient)
	TObjectPtr<UVerticalBox> RootColumn = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UImage> LogoImage = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTextBlock> StatsText = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UVerticalBox> ListBox = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTexture2D> LogoTexture = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTexture2D> ChevronUpTexture = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTexture2D> ChevronDownTexture = nullptr;

	UPROPERTY(Transient)
	TWeakObjectPtr<AShockPlayer> DisplayPlayerOverride;

	int32 SelectedIndex = 0;
	int32 CachedMoney = 0;
	int32 CachedAdam = 0;
	int32 CachedLittleSisters = 0;
	bool bOpen = false;
	bool bDidPause = false;

	static FString LastPauseVerifyError;
};
