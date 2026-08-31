#pragma once

#include "Engine/GameInstance.h"
#include "ShockGameInstance.generated.h"

class AShockPlayer;
class UShockCarryState;

/** Persists carry state across OpenLevel. Set in DefaultEngine.ini via setup_playable_slice.py. */
UCLASS()
class BIOSHOCKRUNTIME_API UShockGameInstance : public UGameInstance
{
	GENERATED_BODY()

public:
	UPROPERTY()
	TObjectPtr<UShockCarryState> PendingCarryState;

	UPROPERTY()
	bool bHasPendingArrival = false;

	UFUNCTION(BlueprintPure, Category = "BioShock|Travel")
	bool HasPendingArrival() const { return bHasPendingArrival && PendingCarryState != nullptr; }

	UFUNCTION(BlueprintPure, Category = "BioShock|Travel")
	FName GetPendingArrivalStartLabel() const;

	void SetPendingCarry(UShockCarryState* State, FName StartLabel);

	UFUNCTION(BlueprintCallable, Category = "BioShock|Travel")
	void SetPendingCarryForVerify(UShockCarryState* State, FName StartLabel) { SetPendingCarry(State, StartLabel); }

	/** Restore onto Player, clear pending, log BIOSHOCK_ARRIVED. Returns false when nothing pending. */
	UFUNCTION(BlueprintCallable, Category = "BioShock|Travel")
	bool ConsumePendingArrival(AShockPlayer* Player);

	UFUNCTION(BlueprintCallable, Category = "BioShock|Travel")
	void ClearPendingArrival();

	UFUNCTION(BlueprintCallable, Category = "BioShock|Travel", meta = (WorldContext = "WorldContextObject"))
	static UShockGameInstance* GetShockInstanceForVerify(UObject* WorldContextObject);

	static UShockGameInstance* GetShockInstance(const UWorld* World);
};
