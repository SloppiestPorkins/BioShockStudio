#pragma once

#include "Blueprint/UserWidget.h"
#include "ShockWeaponSelectScreen.generated.h"

class AShockPlayer;
class UButton;
class UScrollBox;
class UTextBlock;
class UVerticalBox;
class UShockWeaponSelectScreen;

/** One clickable row in the Shift select list. */
UCLASS()
class BIOSHOCKRUNTIME_API UShockSelectListRow : public UUserWidget
{
	GENERATED_BODY()

public:
	void Configure(UShockWeaponSelectScreen* InOwner, int32 InRowIndex, const FString& Label);

protected:
	virtual TSharedRef<SWidget> RebuildWidget() override;

	UFUNCTION()
	void HandleClicked();

	UPROPERTY(Transient)
	TObjectPtr<UButton> RowButton = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTextBlock> RowText = nullptr;

	UPROPERTY(Transient)
	TWeakObjectPtr<UShockWeaponSelectScreen> OwnerScreen;

	int32 RowIndex = 0;
	FString PendingLabel;
};

/** Shift-held full weapon/plasmid select (PCWeaponSelection.swf stand-in). Pauses the game. */
UCLASS()
class BIOSHOCKRUNTIME_API UShockWeaponSelectScreen : public UUserWidget
{
	GENERATED_BODY()

public:
	UShockWeaponSelectScreen(const FObjectInitializer& ObjectInitializer);

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Select")
	void BindDisplayPlayer(AShockPlayer* Player);

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Select")
	void OpenSelectScreen();

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Select")
	void CloseSelectScreen();

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Select")
	bool IsSelectOpen() const { return bOpen; }

	/** Owned weapons + plasmids currently listed. */
	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Select")
	int32 GetListedItemCount() const { return ListedKinds.Num(); }

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Select")
	FString GetListedItemLabel(int32 Index) const;

	/** Equip listed row (weapon → SelectWeaponSlot, plasmid → SelectPlasmidSlot). */
	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Select")
	bool EquipListedItem(int32 Index);

	/** Number-key path: 1..N map to listed rows (same order as the grid). */
	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Select")
	bool EquipByNumberKey(int32 OneBased);

	/** Called by UShockSelectListRow clicks. */
	void HandleRowClicked(int32 Index);

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Select")
	static bool RunHeadlessSelectVerify(UObject* WorldContextObject);

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Select")
	static FString GetLastSelectVerifyError();

protected:
	virtual TSharedRef<SWidget> RebuildWidget() override;
	virtual void NativeConstruct() override;
	virtual FReply NativeOnKeyDown(const FGeometry& InGeometry, const FKeyEvent& InKeyEvent) override;

private:
	enum class EListedKind : uint8
	{
		Weapon,
		Plasmid,
	};

	void EnsureWidgetTree();
	void RebuildList();
	AShockPlayer* ResolvePlayer() const;
	void SetPaused(bool bPause);

	UPROPERTY(Transient)
	TObjectPtr<UVerticalBox> RootColumn = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTextBlock> TitleText = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UScrollBox> ListScroll = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UVerticalBox> ListBox = nullptr;

	UPROPERTY(Transient)
	TWeakObjectPtr<AShockPlayer> DisplayPlayerOverride;

	TArray<EListedKind> ListedKinds;
	TArray<int32> ListedSlots;
	TArray<FString> ListedLabels;
	bool bOpen = false;
	bool bDidPause = false;

	static FString LastSelectVerifyError;
};
