#pragma once

#include "Blueprint/UserWidget.h"
#include "ShockStationTypes.h"
#include "ShockStationMenu.generated.h"

class AShockDoor;
class AShockPlayer;
class AShockStationBase;
class UButton;
class UHorizontalBox;
class UImage;
class UOverlay;
class USizeBox;
class UTextBlock;
class UVerticalBox;
class UShockPlasmid;

/**
 * Shared Deco station chrome: pauses on open, Esc closes, ForceOpenForCapture skips pause.
 * Subclasses fill ContentBox with screen-specific rows.
 */
UCLASS(Abstract)
class BIOSHOCKRUNTIME_API UShockStationMenu : public UUserWidget
{
	GENERATED_BODY()

public:
	UShockStationMenu(const FObjectInitializer& ObjectInitializer);

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Station")
	void BindDisplayPlayer(AShockPlayer* Player);

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Station")
	void BindStation(AShockStationBase* Station);

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Station")
	virtual void OpenStationMenu();

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Station")
	virtual void CloseStationMenu();

	/** Visible for HUD RT capture; does not pause (screenshot timer must keep ticking). */
	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Station")
	virtual void ForceOpenForCapture();

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Station")
	bool IsStationOpen() const { return bOpen; }

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Station")
	virtual bool HasRequiredTextures() const;

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Station")
	static bool RunHeadlessStationsVerify(UObject* WorldContextObject);

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Station")
	static FString GetLastStationsVerifyError();

protected:
	virtual TSharedRef<SWidget> RebuildWidget() override;
	virtual void NativeConstruct() override;
	virtual FReply NativeOnKeyDown(const FGeometry& InGeometry, const FKeyEvent& InKeyEvent) override;

	virtual void EnsureWidgetTree();
	virtual void EnsureTextures();
	virtual void RebuildContent();
	virtual FString GetStationTitle() const { return TEXT("Station"); }
	virtual const TCHAR* GetFaceTexturePath() const { return nullptr; }

	AShockPlayer* ResolvePlayer() const;
	AShockStationBase* ResolveStation() const;
	void SetPaused(bool bPause);

	UPROPERTY(Transient)
	TObjectPtr<UVerticalBox> RootColumn = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<USizeBox> PanelSize = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UOverlay> PanelOverlay = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UImage> FaceImage = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UImage> PanelFrame = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UImage> SlotGridImage = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTextBlock> TitleText = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTextBlock> StatusText = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UVerticalBox> ContentBox = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTexture2D> FaceTexture = nullptr;

	UPROPERTY(Transient)
	TWeakObjectPtr<AShockPlayer> DisplayPlayerOverride;

	UPROPERTY(Transient)
	TWeakObjectPtr<AShockStationBase> BoundStation;

	bool bOpen = false;
	bool bDidPause = false;

	static FString LastStationsVerifyError;
};

/** Circus of Values / El Ammo Bandito — buy from a per-machine stock list. */
UCLASS()
class BIOSHOCKRUNTIME_API UShockVendingMenu : public UShockStationMenu
{
	GENERATED_BODY()

public:
	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Station|Vend")
	bool BuyItem(int32 Index);

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Station|Vend")
	int32 GetListedItemCount() const { return ListedItems.Num(); }

protected:
	virtual void RebuildContent() override;
	virtual FString GetStationTitle() const override { return TEXT("Vending Machine"); }
	virtual const TCHAR* GetFaceTexturePath() const override
	{
		return TEXT("/Game/BioShockUI/Station/T_Station_Vend_Face.T_Station_Vend_Face");
	}

	TArray<FShockVendItem> ListedItems;
};

/**
 * Gene Bank — owned plasmids equip/unequip to EquippedPlasmids slots.
 * Gap: no gene-tonic system in BioShockRuntime yet — plasmids only.
 */
UCLASS()
class BIOSHOCKRUNTIME_API UShockGeneBankMenu : public UShockStationMenu
{
	GENERATED_BODY()

public:
	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Station|GeneBank")
	bool EquipOwnedPlasmid(int32 OwnedIndex, int32 PlasmidSlot);

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Station|GeneBank")
	bool UnequipPlasmidSlot(int32 PlasmidSlot);

protected:
	virtual void RebuildContent() override;
	virtual FString GetStationTitle() const override
	{
		return TEXT("Gene Bank (plasmids only — no tonic system yet)");
	}
	virtual const TCHAR* GetFaceTexturePath() const override
	{
		return TEXT("/Game/BioShockUI/Station/T_Station_Gene_Panel.T_Station_Gene_Panel");
	}
};

/**
 * U-Invent — craft from recipes against AShockPlayer inventory stacks.
 * Gap: no dedicated crafting-component inventory; uses ItemClass stacks (Glue/Rubber/…).
 */
UCLASS()
class BIOSHOCKRUNTIME_API UShockUInventMenu : public UShockStationMenu
{
	GENERATED_BODY()

public:
	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Station|UInvent")
	bool CraftRecipe(int32 RecipeIndex);

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Station|UInvent")
	int32 GetRecipeCount() const { return Recipes.Num(); }

	static void BuildDefaultRecipes(TArray<FShockCraftRecipe>& OutRecipes);

protected:
	virtual void RebuildContent() override;
	virtual FString GetStationTitle() const override
	{
		return TEXT("U-Invent (uses inventory stacks — no component bag yet)");
	}
	virtual const TCHAR* GetFaceTexturePath() const override
	{
		return TEXT("/Game/BioShockUI/Station/T_Station_Invent_Face.T_Station_Invent_Face");
	}

	TArray<FShockCraftRecipe> Recipes;
};

/** Gatherer's Garden — spend ADAM on Health/EVE max, plasmid slots, or a plasmid. */
UCLASS()
class BIOSHOCKRUNTIME_API UShockGathererGardenMenu : public UShockStationMenu
{
	GENERATED_BODY()

public:
	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Station|Garden")
	bool PurchaseUpgrade(EShockGardenUpgrade Upgrade);

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|UI|Station|Garden")
	int32 HealthUpgradeCost = 20;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|UI|Station|Garden")
	float HealthUpgradeAmount = 20.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|UI|Station|Garden")
	int32 EveUpgradeCost = 20;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|UI|Station|Garden")
	float EveUpgradeAmount = 20.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|UI|Station|Garden")
	int32 SlotUpgradeCost = 50;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|UI|Station|Garden")
	int32 PlasmidBuyCost = 40;

protected:
	virtual void RebuildContent() override;
	virtual FString GetStationTitle() const override { return TEXT("Gatherer's Garden"); }
	virtual const TCHAR* GetFaceTexturePath() const override
	{
		return TEXT("/Game/BioShockUI/Station/T_Station_Garden_Banner.T_Station_Garden_Banner");
	}
};

/** Three-digit combo lock — correct Code unlocks/opens the linked door. */
UCLASS()
class BIOSHOCKRUNTIME_API UShockComboLockMenu : public UShockStationMenu
{
	GENERATED_BODY()

public:
	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Station|Combo")
	void SetDial(int32 DialIndex, int32 Digit);

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Station|Combo")
	void NudgeDial(int32 DialIndex, int32 Delta);

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Station|Combo")
	bool TrySubmitCode();

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Station|Combo")
	int32 GetEnteredCode() const;

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Station|Combo")
	bool WasLastSubmitCorrect() const { return bLastSubmitCorrect; }

protected:
	virtual void RebuildContent() override;
	virtual FString GetStationTitle() const override { return TEXT("Combo Lock"); }
	virtual const TCHAR* GetFaceTexturePath() const override
	{
		return TEXT("/Game/BioShockUI/Station/T_Station_Combo_Dial.T_Station_Combo_Dial");
	}

	int32 Dials[3] = {0, 0, 0};
	bool bLastSubmitCorrect = false;
};
