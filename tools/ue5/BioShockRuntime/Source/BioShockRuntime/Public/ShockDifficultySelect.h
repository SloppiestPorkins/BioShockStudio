#pragma once

#include "Blueprint/UserWidget.h"
#include "ShockDifficulty.h"
#include "ShockDifficultySelect.generated.h"

class UButton;
class UHorizontalBox;
class UImage;
class UTextBlock;
class UVerticalBox;
class UShockDifficultySelect;

UCLASS()
class BIOSHOCKRUNTIME_API UShockDifficultySelectRow : public UUserWidget
{
	GENERATED_BODY()

public:
	void Configure(
		UShockDifficultySelect* InOwner,
		int32 InRowIndex,
		EShockDifficulty Diff,
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
	TObjectPtr<UTextBlock> NameText = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTextBlock> DescText = nullptr;

	UPROPERTY(Transient)
	TWeakObjectPtr<UShockDifficultySelect> OwnerMenu;

	int32 RowIndex = 0;
	EShockDifficulty PendingDiff = EShockDifficulty::Medium;
	bool bPendingSelected = false;
	TWeakObjectPtr<UTexture2D> PendingChevron;
};

/**
 * New Game difficulty picker: Easy / Medium / Hard / Survivor.
 * Selecting one stores difficulty on UShockGameInstance and requests travel to the first level.
 */
UCLASS()
class BIOSHOCKRUNTIME_API UShockDifficultySelect : public UUserWidget
{
	GENERATED_BODY()

public:
	UShockDifficultySelect(const FObjectInitializer& ObjectInitializer);

	/** First playable map — Medical slice (PlayerStart + ShockGameMode). Welcome lacks a spawn-ready start. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Menu")
	FString FirstLevelPath = TEXT("/Game/BioShockSlice/1-Medical");

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Menu")
	FString TravelOptions = TEXT("game=/Script/BioShockRuntime.ShockGameMode");

	UFUNCTION(BlueprintCallable, Category = "BioShock|Menu")
	void OpenDifficultySelect();

	UFUNCTION(BlueprintCallable, Category = "BioShock|Menu")
	void CloseDifficultySelect();

	UFUNCTION(BlueprintCallable, Category = "BioShock|Menu")
	void SetSelectedIndex(int32 Index);

	UFUNCTION(BlueprintPure, Category = "BioShock|Menu")
	int32 GetSelectedIndex() const { return SelectedIndex; }

	UFUNCTION(BlueprintPure, Category = "BioShock|Menu")
	int32 GetOptionCount() const { return 4; }

	UFUNCTION(BlueprintCallable, Category = "BioShock|Menu")
	void ConfirmSelection();

	/** Last difficulty confirmed via ConfirmSelection (headless-friendly even without GI). */
	UFUNCTION(BlueprintPure, Category = "BioShock|Menu")
	EShockDifficulty GetLastConfirmedDifficulty() const { return LastConfirmedDifficulty; }

	UFUNCTION(BlueprintPure, Category = "BioShock|Menu")
	FString GetLastTravelRequestMap() const { return LastTravelRequestMap; }

	void HandleRowClicked(int32 Index);

	UFUNCTION(BlueprintCallable, Category = "BioShock|Menu")
	static bool RunHeadlessDifficultyVerify(UObject* WorldContextObject);

	UFUNCTION(BlueprintPure, Category = "BioShock|Menu")
	static FString GetLastDifficultyVerifyError();

protected:
	virtual TSharedRef<SWidget> RebuildWidget() override;
	virtual void NativeConstruct() override;
	virtual FReply NativeOnKeyDown(const FGeometry& InGeometry, const FKeyEvent& InKeyEvent) override;

private:
	void EnsureWidgetTree();
	void EnsureTextures();
	void RebuildList();

	UPROPERTY(Transient)
	TObjectPtr<UVerticalBox> RootColumn = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTextBlock> HeaderText = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UVerticalBox> ListBox = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UButton> BackButton = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTexture2D> ChevronTexture = nullptr;

	int32 SelectedIndex = 1; // Medium default
	bool bOpen = false;
	EShockDifficulty LastConfirmedDifficulty = EShockDifficulty::Medium;
	FString LastTravelRequestMap;

	static FString LastVerifyError;

	UFUNCTION()
	void OnBackClicked();
};
