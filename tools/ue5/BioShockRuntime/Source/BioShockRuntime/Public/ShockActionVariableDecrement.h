#pragma once

#include "ShockAction.h"
#include "ShockActionVariableDecrement.generated.h"

class UShockVariableScope;

/** UnrealScript `ActionVariableDecrement`: subtracts 1 from a named variable. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionVariableDecrement : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionVariableDecrement();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName Target;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InTarget);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetTarget() const { return Target; }

	/** Decrements Target in Scope (numeric string). Creates as "-1" if missing. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool ApplyToScope(UShockVariableScope* Scope);
};
