#pragma once

#include "UObject/Object.h"
#include "ShockCarryState.generated.h"

class AShockPlayer;

/** Serialized weapon holster entry for level travel. */
USTRUCT(BlueprintType)
struct FShockCarriedWeapon
{
	GENERATED_BODY()

	UPROPERTY()
	FName DefName;

	/** Set when DefName is empty (e.g. ResearchCamera). */
	UPROPERTY()
	FString ClassPath;

	UPROPERTY()
	int32 Slot = -1;

	UPROPERTY()
	int32 Mag = 0;

	UPROPERTY()
	int32 Reserve = 0;
};

/** Serialized plasmid slot for level travel. */
USTRUCT(BlueprintType)
struct FShockCarriedPlasmid
{
	GENERATED_BODY()

	UPROPERTY()
	FName PlasmidName;

	UPROPERTY()
	int32 Slot = -1;
};

/**
 * Player-state blob that survives OpenLevel via UShockGameInstance::PendingCarryState.
 * Health, EVE, holster, plasmids, research, inventory, and money.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockCarryState : public UObject
{
	GENERATED_BODY()

public:
	UPROPERTY()
	float Health = 0.0f;

	UPROPERTY()
	float MaxEve = 100.0f;

	UPROPERTY()
	float CurrentEve = 0.0f;

	UPROPERTY()
	TArray<FShockCarriedWeapon> Weapons;

	UPROPERTY()
	int32 ActiveWeaponSlot = -1;

	UPROPERTY()
	TArray<FShockCarriedPlasmid> Plasmids;

	UPROPERTY()
	int32 ActivePlasmidSlot = 0;

	UPROPERTY()
	TMap<FName, float> Research;

	UPROPERTY()
	TMap<FName, int32> Inventory;

	UPROPERTY()
	int32 Money = 0;

	/** PlayerStart / arrival label on the destination map. */
	UPROPERTY()
	FString ArrivalStartLabel;

	UFUNCTION(BlueprintCallable, Category = "BioShock|Travel")
	static UShockCarryState* Capture(AShockPlayer* Player);

	UFUNCTION(BlueprintCallable, Category = "BioShock|Travel")
	void RestoreOnto(AShockPlayer* Player) const;

	UFUNCTION(BlueprintPure, Category = "BioShock|Travel")
	int32 GetWeaponCount() const { return Weapons.Num(); }

	UFUNCTION(BlueprintPure, Category = "BioShock|Travel")
	int32 GetPlasmidCount() const { return Plasmids.Num(); }
};
