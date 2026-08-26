#pragma once

#include "ShockAction.h"
#include "ShockActionRetractFact.generated.h"

/**
 * UnrealScript `ActionRetractFact` (ActionFact): set fact false via Slot_1/2/3.
 * First slice records the pattern; no FactDatabase yet.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionRetractFact : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionRetractFact();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName Slot1;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString Slot2;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString Slot3;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastSlot1;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InSlot1, const FString& InSlot2, const FString& InSlot3);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastSlot1() const { return LastSlot1; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestRetract();
};
