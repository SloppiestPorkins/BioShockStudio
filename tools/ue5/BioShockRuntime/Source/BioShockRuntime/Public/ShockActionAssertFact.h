#pragma once

#include "ShockAction.h"
#include "ShockActionAssertFact.generated.h"

class UWorld;

/**
 * UnrealScript `ActionAssertFact` (extends ActionFact): AssertFact on Slot_1/2/3 pattern.
 * ApplyInWorld inserts the key into the local ShockPlayer fact set.
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

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
