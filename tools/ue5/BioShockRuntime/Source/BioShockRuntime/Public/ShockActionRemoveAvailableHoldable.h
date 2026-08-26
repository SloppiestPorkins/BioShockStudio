#pragma once

#include "ShockAction.h"
#include "ShockActionRemoveAvailableHoldable.generated.h"

/** UnrealScript `ActionRemoveAvailableHoldable`. Records HoldableClass; no inventory yet. */
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
};
