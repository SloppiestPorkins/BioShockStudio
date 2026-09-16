#pragma once

#include "GameFramework/Actor.h"
#include "ShockSearchableContainer.generated.h"

class AShockPlayer;
class USphereComponent;
class UStaticMeshComponent;

USTRUCT(BlueprintType)
struct BIOSHOCKRUNTIME_API FShockContainerSlot
{
	GENERATED_BODY()

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Container")
	FName ItemClass;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Container")
	int32 StackSize = 0;
};

/**
 * A corpse / cash register / vase / booty stash the player searches with Interact. One search
 * grants its loot (money + an optional item), then it is spent. Loot is authored per record;
 * where the manifest gives none, a small money roll is used and reported as an approximation.
 */
UCLASS()
class BIOSHOCKRUNTIME_API AShockSearchableContainer : public AActor
{
	GENERATED_BODY()

public:
	AShockSearchableContainer();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	TObjectPtr<USphereComponent> Reach;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	TObjectPtr<UStaticMeshComponent> Mesh;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Container")
	FName ScriptLabel;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Container")
	int32 LootMoneyMin = 1;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Container")
	int32 LootMoneyMax = 24;

	/** Optional inventory item dropped alongside the money (e.g. FirstAidKit, EveHypo). */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Container")
	FName LootItemClass;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Container")
	int32 LootItemAmount = 1;

	UPROPERTY(VisibleInstanceOnly, BlueprintReadOnly, Category="BioShock|Container")
	bool bSearched = false;

	/** Script-authored fixed slots used by ActionPlaceItemInContainerSlot. */
	UPROPERTY(VisibleInstanceOnly, BlueprintReadOnly, Category="BioShock|Container")
	TMap<int32, FShockContainerSlot> ScriptedSlots;

	UFUNCTION(BlueprintCallable, Category="BioShock|Container")
	void ConfigureContainer(FName InLabel, int32 InMoneyMin, int32 InMoneyMax, FName InItemClass, int32 InItemAmount);

	UFUNCTION(BlueprintCallable, Category="BioShock|Container")
	void SetContainerMesh(UStaticMesh* InMesh);

	/** Empty/overwrite replaces the slot; a matching non-overwrite item merges its stack. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Container")
	bool PlaceItemInSlot(int32 Slot, FName ItemClass, int32 StackSize, bool bOverwrite);

	UFUNCTION(BlueprintPure, Category="BioShock|Container")
	FName GetSlotItemClass(int32 Slot) const;

	UFUNCTION(BlueprintPure, Category="BioShock|Container")
	int32 GetSlotStackSize(int32 Slot) const;

	/** Interact / verify entry point. Returns true if this search granted loot. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Container")
	bool Search(AShockPlayer* Player);

	UFUNCTION(BlueprintPure, Category="BioShock|Container")
	bool WasSearchedForVerify() const { return bSearched; }
};
