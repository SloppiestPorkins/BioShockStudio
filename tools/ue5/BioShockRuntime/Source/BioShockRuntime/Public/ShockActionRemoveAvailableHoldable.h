#pragma once

#include "ShockAction.h"
#include "ShockActionRemoveAvailableHoldable.generated.h"

class UWorld;

/** UnrealScript `ActionRemoveAvailableHoldable`. ApplyInWorld removes holdable from ShockPlayer store. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionRemoveAvailableHoldable : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionRemoveAvailableHoldable();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName HoldableClass;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastHoldableClass;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InHoldable);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastHoldableClass() const { return LastHoldableClass; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestRemove();

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
