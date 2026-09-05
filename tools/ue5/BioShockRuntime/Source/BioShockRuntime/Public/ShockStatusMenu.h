#pragma once

#include "Blueprint/UserWidget.h"
#include "ShockStatusMenu.generated.h"

class AShockPlayer;
class UButton;
class UCanvasPanel;
class UHorizontalBox;
class UImage;
class UScrollBox;
class UTextBlock;
class UVerticalBox;
class UShockStatusMenu;

UENUM(BlueprintType)
enum class EShockStatusTab : uint8
{
	Map UMETA(DisplayName = "Map"),
	Goals UMETA(DisplayName = "Goals"),
	Messages UMETA(DisplayName = "Messages"),
	Help UMETA(DisplayName = "Help"),
};

/** One clickable tab button across the top of the status overlay. */
UCLASS()
class BIOSHOCKRUNTIME_API UShockStatusTabButton : public UUserWidget
{
	GENERATED_BODY()

public:
	void Configure(UShockStatusMenu* InOwner, EShockStatusTab InTab, UTexture2D* Icon, const FString& Label);

protected:
	virtual TSharedRef<SWidget> RebuildWidget() override;

	UFUNCTION()
	void HandleClicked();

	UPROPERTY(Transient)
	TObjectPtr<UButton> TabButton = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UImage> TabIcon = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTextBlock> TabLabel = nullptr;

	UPROPERTY(Transient)
	TWeakObjectPtr<UShockStatusMenu> OwnerMenu;

	EShockStatusTab Tab = EShockStatusTab::Map;
	TWeakObjectPtr<UTexture2D> PendingIcon;
	FString PendingLabel;
};

/**
 * Full-screen paused status overlay (mapsPC / ingamemanualPC stand-in).
 * Tabs: Map (placeholder), Goals (quests), Messages (diaries — empty until wired), Help.
 */
UCLASS()
class BIOSHOCKRUNTIME_API UShockStatusMenu : public UUserWidget
{
	GENERATED_BODY()

public:
	UShockStatusMenu(const FObjectInitializer& ObjectInitializer);

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Status")
	void BindDisplayPlayer(AShockPlayer* Player);

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Status")
	void OpenStatusMenu();

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Status")
	void CloseStatusMenu();

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Status")
	void ForceOpenForCapture();

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Status")
	bool IsStatusOpen() const { return bOpen; }

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Status")
	void SetActiveTab(EShockStatusTab Tab);

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Status")
	void StepTab(int32 Delta);

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Status")
	EShockStatusTab GetActiveTab() const { return ActiveTab; }

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Status")
	int32 GetListedGoalCount() const { return ListedGoalNames.Num(); }

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Status")
	FString GetListedGoalLabel(int32 Index) const;

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Status")
	bool HasRequiredTextures() const;

	/** Called by UShockStatusTabButton clicks. */
	void HandleTabClicked(EShockStatusTab Tab);

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Status")
	static bool RunHeadlessStatusVerify(UObject* WorldContextObject);

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Status")
	static FString GetLastStatusVerifyError();

protected:
	virtual TSharedRef<SWidget> RebuildWidget() override;
	virtual void NativeConstruct() override;
	virtual FReply NativeOnKeyDown(const FGeometry& InGeometry, const FKeyEvent& InKeyEvent) override;

private:
	void EnsureWidgetTree();
	void EnsureTextures();
	void RebuildContent();
	void RebuildGoalsList();
	void RebuildMessagesPanel();
	void RebuildHelpCards();
	void RebuildMapPanel();
	AShockPlayer* ResolvePlayer() const;
	void SetPaused(bool bPause);

	UPROPERTY(Transient)
	TObjectPtr<UVerticalBox> RootColumn = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UImage> PanelFrame = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UHorizontalBox> TabRow = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UImage> Nameplate = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTextBlock> TitleText = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UScrollBox> ContentScroll = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UVerticalBox> ContentBox = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTexture2D> TabTextures[4];

	UPROPERTY(Transient)
	TObjectPtr<UTexture2D> PanelTexture = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTexture2D> NameplateTexture = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTexture2D> HelpTextures[4];

	UPROPERTY(Transient)
	TWeakObjectPtr<AShockPlayer> DisplayPlayerOverride;

	TArray<FName> ListedGoalNames;
	TArray<FString> ListedGoalLabels;
	EShockStatusTab ActiveTab = EShockStatusTab::Map;
	bool bOpen = false;
	bool bDidPause = false;

	static FString LastStatusVerifyError;
};
