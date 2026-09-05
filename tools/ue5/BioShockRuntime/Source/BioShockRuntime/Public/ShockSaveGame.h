#pragma once

#include "GameFramework/SaveGame.h"
#include "ShockCarryState.h"
#include "ShockDifficulty.h"
#include "ShockSaveGame.generated.h"

/**
 * Slot save: UShockCarryState blob + level path + timestamp + difficulty.
 * Wired through UGameplayStatics::SaveGameToSlot / LoadGameFromSlot.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockSaveGame : public USaveGame
{
	GENERATED_BODY()

public:
	UPROPERTY(VisibleAnywhere, Category = "BioShock|Save")
	FString SlotDisplayName;

	UPROPERTY(VisibleAnywhere, Category = "BioShock|Save")
	FString LevelPackagePath;

	UPROPERTY(VisibleAnywhere, Category = "BioShock|Save")
	FString LevelDisplayName;

	/** UTC ticks (FDateTime::UtcNow().GetTicks()) when saved. */
	UPROPERTY(VisibleAnywhere, Category = "BioShock|Save")
	int64 SavedUtcTicks = 0;

	UPROPERTY(VisibleAnywhere, Category = "BioShock|Save")
	EShockDifficulty Difficulty = EShockDifficulty::Medium;

	UPROPERTY(VisibleAnywhere, Category = "BioShock|Save")
	float Health = 0.0f;

	UPROPERTY(VisibleAnywhere, Category = "BioShock|Save")
	float MaxEve = 100.0f;

	UPROPERTY(VisibleAnywhere, Category = "BioShock|Save")
	float CurrentEve = 0.0f;

	UPROPERTY(VisibleAnywhere, Category = "BioShock|Save")
	TArray<FShockCarriedWeapon> Weapons;

	UPROPERTY(VisibleAnywhere, Category = "BioShock|Save")
	int32 ActiveWeaponSlot = -1;

	UPROPERTY(VisibleAnywhere, Category = "BioShock|Save")
	TArray<FShockCarriedPlasmid> Plasmids;

	UPROPERTY(VisibleAnywhere, Category = "BioShock|Save")
	int32 ActivePlasmidSlot = 0;

	UPROPERTY(VisibleAnywhere, Category = "BioShock|Save")
	TMap<FName, float> Research;

	UPROPERTY(VisibleAnywhere, Category = "BioShock|Save")
	TMap<FName, int32> Inventory;

	UPROPERTY(VisibleAnywhere, Category = "BioShock|Save")
	int32 Money = 0;

	UPROPERTY(VisibleAnywhere, Category = "BioShock|Save")
	FString ArrivalStartLabel;

	UFUNCTION(BlueprintCallable, Category = "BioShock|Save")
	void CaptureFromCarryState(const UShockCarryState* Carry, EShockDifficulty InDifficulty);

	UFUNCTION(BlueprintCallable, Category = "BioShock|Save")
	UShockCarryState* RestoreToCarryState(UObject* Outer = nullptr) const;

	UFUNCTION(BlueprintPure, Category = "BioShock|Save")
	FString GetTimestampDisplay() const;

	static FString MakeSlotName(int32 SlotIndex);
	static constexpr int32 MaxSlots = 8;
};
