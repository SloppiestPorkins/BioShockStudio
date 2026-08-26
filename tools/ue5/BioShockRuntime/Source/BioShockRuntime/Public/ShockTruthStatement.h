#pragma once

#include "ShockActionBool.h"
#include "ShockTruthStatement.generated.h"

/**
 * UnrealScript `TruthStatement`. `Value` is a name interpreted as a boolean
 * (`bool(string(Value))` in script when VariableBool is the best class).
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockTruthStatement : public UShockActionBool
{
	GENERATED_BODY()

public:
	UShockTruthStatement();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName Value;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InValue);

	virtual bool EvaluateBool() const override;
};
