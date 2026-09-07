#pragma once

#include "Blueprint/UserWidget.h"
#include "ShockMainMenuWidget.generated.h"

class UBorder;
class UButton;
class UHorizontalBox;
class UImage;
class UOverlay;
class UTextBlock;
class UVerticalBox;
class UShockDifficultySelect;
class UShockSaveLoadMenu;
class UShockStubMenu;
class UShockMainMenuWidget;

/** One selectable main-menu row with gold-chevron highlight. */
UCLASS()
class BIOSHOCKRUNTIME_API UShockMainMenuRow : public UUserWidget
{
	GENERATED_BODY()

public:
	void Configure(
		UShockMainMenuWidget* InOwner,
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
	TObjectPtr<UOverlay> RowOverlay = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UImage> PlateImage = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UHorizontalBox> RowBox = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UImage> Chevron = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTextBlock> RowText = nullptr;

	UPROPERTY(Transient)
	TWeakObjectPtr<UShockMainMenuWidget> OwnerMenu;

	int32 RowIndex = 0;
	FString PendingLabel;
	bool bPendingSelected = false;
	TWeakObjectPtr<UTexture2D> PendingChevron;
};

/**
 * Front-end start screen: BioShock logo + New Game / Continue / Load / Options /
 * Credits / Director's Commentary / Museum / Challenge Rooms / Exit.
 */
UCLASS()
class BIOSHOCKRUNTIME_API UShockMainMenuWidget : public UUserWidget
{
	GENERATED_BODY()

public:
	UShockMainMenuWidget(const FObjectInitializer& ObjectInitializer);

	/** Package path of the first playable map (Medical slice — spawn-ready PlayerStart). */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Menu")
	FString PlayLevelPath;

	/** Travel options for OpenLevel (no leading '?'). Hands control to ShockGameMode possess path. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Menu")
	FString PlayTravelOptions;

	/** Legacy alias — opens difficulty select (New Game). */
	UFUNCTION(BlueprintCallable, Category = "BioShock|Menu")
	void OnPlayClicked();

	UFUNCTION(BlueprintCallable, Category = "BioShock|Menu")
	void OnOptionsClicked();

	UFUNCTION(BlueprintCallable, Category = "BioShock|Menu")
	void OnQuitClicked();

	UFUNCTION(BlueprintPure, Category = "BioShock|Menu")
	FString GetResolvedPlayLevelPath() const;

	UFUNCTION(BlueprintPure, Category = "BioShock|Menu")
	int32 GetMenuEntryCount() const;

	UFUNCTION(BlueprintPure, Category = "BioShock|Menu")
	int32 GetSelectedIndex() const { return SelectedIndex; }

	UFUNCTION(BlueprintCallable, Category = "BioShock|Menu")
	void SetSelectedIndex(int32 Index);

	UFUNCTION(BlueprintCallable, Category = "BioShock|Menu")
	void ActivateSelected();

	void HandleRowClicked(int32 Index);

	UFUNCTION(BlueprintCallable, Category = "BioShock|Menu")
	static bool RunHeadlessMainMenuVerify(UObject* WorldContextObject);

	UFUNCTION(BlueprintPure, Category = "BioShock|Menu")
	static FString GetLastMainMenuVerifyError();

	UFUNCTION(BlueprintCallable, Category = "BioShock|Menu")
	static bool RunHeadlessFrontendVerify(UObject* WorldContextObject);

	UFUNCTION(BlueprintPure, Category = "BioShock|Menu")
	static FString GetLastFrontendVerifyError();

protected:
	virtual TSharedRef<SWidget> RebuildWidget() override;
	virtual void NativeConstruct() override;
	virtual FReply NativeOnKeyDown(const FGeometry& InGeometry, const FKeyEvent& InKeyEvent) override;

private:
	// Order and wording match BioShock Remastered's front end: Continue (only when a save
	// exists) / New Game / Load Game / Options / Extras / Credits / Quit.
	enum class EMainMenuAction : uint8
	{
		Continue = 0,
		NewGame,
		LoadGame,
		Options,
		Extras,
		Credits,
		Quit,
		Count
	};

	void EnsureWidgetTree();
	void EnsureTextures();
	void RebuildList();
	void OpenDifficulty();
	void OpenSaveLoad(bool bSaveMode);
	void OpenStub(const FString& Title);
	void TryContinue();
	static const TCHAR* ActionLabel(int32 Index);
	/** True when any save slot holds a game — gates the Continue entry. */
	bool HasAnySave() const;
	/** Menu actions shown this frame, in order (Continue dropped when HasAnySave() is false). */
	TArray<EMainMenuAction> BuildVisibleActions() const;

	/** Rebuilt every RebuildList(); SelectedIndex and row indices are into this. */
	TArray<EMainMenuAction> VisibleActions;

	UPROPERTY(Transient)
	TObjectPtr<UBorder> RootBorder = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UVerticalBox> RootBox = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UImage> LogoImage = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTextBlock> TitleFallback = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UVerticalBox> ListBox = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTexture2D> LogoTexture = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTexture2D> ChevronTexture = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UShockDifficultySelect> DifficultySelect = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UShockSaveLoadMenu> SaveLoadMenu = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UShockStubMenu> StubMenu = nullptr;

	int32 SelectedIndex = 0;

	static FString LastMainMenuVerifyError;
	static FString LastFrontendVerifyError;

	// Kept for WBP / old bindings — not used after list rebuild.
	UPROPERTY(Transient)
	TObjectPtr<UButton> PlayButton = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UButton> OptionsButton = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UButton> QuitButton = nullptr;
};
