#pragma once

#include "Blueprint/UserWidget.h"
#include "ShockHackingTypes.h"
#include "ShockHackingMinigame.generated.h"

class AShockPlayer;
class AShockSecurityDevice;
class UButton;
class UHorizontalBox;
class UImage;
class UTextBlock;
class UUniformGridPanel;
class UVerticalBox;

/**
 * BioShock hackingPC pipe-puzzle (Phase U6).
 * Board model + fluid flood/progress; chrome from hackingPC bitmaps when imported;
 * pipe segments drawn as UMG shapes (vector tile sprites deferred — logic first).
 */
UCLASS()
class BIOSHOCKRUNTIME_API UShockHackingMinigame : public UUserWidget
{
	GENERATED_BODY()

public:
	UShockHackingMinigame(const FObjectInitializer& ObjectInitializer);

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Hacking")
	void BindDisplayPlayer(AShockPlayer* Player);

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Hacking")
	void BindDevice(AShockSecurityDevice* Device);

	/** Build a difficulty-scaled board and start fluid after a short delay. */
	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Hacking")
	void OpenMinigame(float Difficulty01);

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Hacking")
	void CloseMinigame();

	/** Visible for HUD RT capture; does not pause. */
	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Hacking")
	void ForceOpenForCapture();

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Hacking")
	bool IsMinigameOpen() const { return bOpen; }

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Hacking")
	EShockHackResult GetResult() const { return Result; }

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Hacking")
	int32 GetBoardWidth() const { return BoardWidth; }

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Hacking")
	int32 GetBoardHeight() const { return BoardHeight; }

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Hacking")
	int32 GetFaceDownCount() const;

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Hacking")
	float GetFluidProgress() const { return FluidProgress; }

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Hacking")
	float GetFluidSpeed() const { return FluidSpeed; }

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Hacking")
	bool HasPathSourceToTarget() const;

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Hacking")
	bool RevealTile(int32 Index);

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Hacking")
	bool SwapTiles(int32 IndexA, int32 IndexB);

	/** Advance fluid / timer (headless + NativeTick). */
	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Hacking")
	void AdvanceMinigame(float DeltaSeconds);

	/** Spend Money for instant success. */
	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Hacking")
	bool TryBuyOut();

	/**
	 * Instant success. Consumes inventory AutoHackTool when present;
	 * if none, still succeeds (gap: Auto-Hack Tool always available — noted).
	 */
	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Hacking")
	bool TryAutoHack();

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Hacking")
	int32 GetBuyOutCost() const { return BuyOutCost; }

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Hacking")
	bool DidCallSetSecurityHacked() const { return bDidSetSecurityHacked; }

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Hacking")
	bool DidRaiseAlarm() const { return bDidRaiseAlarm; }

	/** Deterministic nearly-solved corridor; OutSwap pairs complete the path. */
	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Hacking")
	void BuildScriptedWinBoard(TArray<int32>& OutSwapA, TArray<int32>& OutSwapB);

	/** Dead-end path so advancing fluid fails without a win. */
	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Hacking")
	void BuildScriptedLoseBoard();

	/** Connected path that routes through an Alarm hazard. */
	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Hacking")
	void BuildScriptedAlarmBoard();

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Hacking")
	static bool RunHeadlessHackingMinigameVerify(UObject* WorldContextObject);

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Hacking")
	static FString GetLastHackingMinigameVerifyError();

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|UI|Hacking")
	int32 BuyOutCost = 50;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|UI|Hacking")
	float HackShutdownSeconds = 8.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|UI|Hacking")
	float OverloadDamage = 15.0f;

	/** Inventory ItemClass for Auto-Hack Tool (consumed when present). */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|UI|Hacking")
	FName AutoHackItemClass = TEXT("AutoHackTool");

protected:
	virtual TSharedRef<SWidget> RebuildWidget() override;
	virtual void NativeConstruct() override;
	virtual void NativeTick(const FGeometry& MyGeometry, float InDeltaTime) override;
	virtual FReply NativeOnKeyDown(const FGeometry& InGeometry, const FKeyEvent& InKeyEvent) override;

	void EnsureWidgetTree();
	void EnsureTextures();
	void RebuildBoardVisual();
	void RefreshStatusText();
	void SetPaused(bool bPause);

	AShockPlayer* ResolvePlayer() const;
	AShockSecurityDevice* ResolveDevice() const;

	void BuildBoardForDifficulty(float Difficulty01);
	void ScaleParamsFromDifficulty(float Difficulty01);
	void BeginPlaying();
	void FinishWin();
	void FinishFail(bool bFromOverload);
	void ApplyHackSuccessToWorld();

	int32 IndexAt(int32 X, int32 Y) const;
	bool InBounds(int32 X, int32 Y) const;
	uint8 PortsForTile(const FShockHackTile& Tile) const;
	bool TilesConnect(int32 IndexA, int32 IndexB) const;
	bool FindPath(TArray<int32>& OutPath) const;
	void RecomputePath();

	UPROPERTY(Transient)
	TArray<FShockHackTile> Tiles;

	UPROPERTY(Transient)
	TArray<int32> CurrentPath;

	int32 BoardWidth = 0;
	int32 BoardHeight = 0;
	int32 SourceIndex = INDEX_NONE;
	int32 TargetIndex = INDEX_NONE;

	float Difficulty = 0.5f;
	float FluidSpeed = 0.12f;
	float FluidProgress = 0.0f;
	float FluidDelayRemaining = 1.0f;
	float SpeedMultiplier = 1.0f;

	EShockHackResult Result = EShockHackResult::Playing;
	bool bOpen = false;
	bool bDidPause = false;
	bool bDidSetSecurityHacked = false;
	bool bDidRaiseAlarm = false;
	bool bAlarmTriggered = false;
	TSet<int32> HazardsTriggered;

	int32 SelectedTileIndex = INDEX_NONE;

	UPROPERTY(Transient)
	TObjectPtr<UVerticalBox> RootColumn = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UImage> BezelImage = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UImage> HazardStripImage = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTextBlock> TitleText = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTextBlock> StatusText = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UUniformGridPanel> BoardGrid = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UHorizontalBox> OptionsRow = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTexture2D> BezelTexture = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTexture2D> HazardStripTexture = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTexture2D> BannerTexture = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTexture2D> RingTexture = nullptr;

	UPROPERTY(Transient)
	TWeakObjectPtr<AShockPlayer> DisplayPlayerOverride;

	UPROPERTY(Transient)
	TWeakObjectPtr<AShockSecurityDevice> BoundDevice;

	static FString LastHackingMinigameVerifyError;
};
