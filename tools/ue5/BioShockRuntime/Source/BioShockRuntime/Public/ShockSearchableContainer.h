#pragma once

#include "GameFramework/Actor.h"
#include "ShockSearchableContainer.generated.h"

class AShockPlayer;
class USphereComponent;
class UStaticMeshComponent;

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

	UFUNCTION(BlueprintCallable, Category="BioShock|Container")
	void ConfigureContainer(FName InLabel, int32 InMoneyMin, int32 InMoneyMax, FName InItemClass, int32 InItemAmount);

	UFUNCTION(BlueprintCallable, Category="BioShock|Container")
	void SetContainerMesh(UStaticMesh* InMesh);

	/** Interact / verify entry point. Returns true if this search granted loot. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Container")
	bool Search(AShockPlayer* Player);

	UFUNCTION(BlueprintPure, Category="BioShock|Container")
	bool WasSearchedForVerify() const { return bSearched; }
};
