#pragma once

#include "ShockAction.h"
#include "ShockActionAssertFact.generated.h"

/**
 * UnrealScript `ActionAssertFact` (extends ActionFact): AssertFact on Slot_1/2/3 pattern.
 * First slice records the pattern + assert request; no FactDatabase yet.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionAssertFact : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionAssertFact();

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
	bool RequestAssert();
};
