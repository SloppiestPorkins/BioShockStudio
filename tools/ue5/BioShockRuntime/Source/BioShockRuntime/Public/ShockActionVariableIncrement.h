#pragma once

#include "ShockAction.h"
#include "ShockActionVariableIncrement.generated.h"

class UShockVariableScope;

/** UnrealScript `ActionVariableIncrement`: adds 1 to a named variable. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionVariableIncrement : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionVariableIncrement();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName Target;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InTarget);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetTarget() const { return Target; }

	/** Increments Target in Scope (numeric string). Creates as "1" if missing. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool ApplyToScope(UShockVariableScope* Scope);
};
