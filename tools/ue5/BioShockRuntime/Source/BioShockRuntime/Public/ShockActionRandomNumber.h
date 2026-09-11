#pragma once

#include "ShockAction.h"
#include "ShockActionRandomNumber.generated.h"

/** Scripting.ActionRandomNumber: returns a VariableFloat in the authored inclusive range. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionRandomNumber : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionRandomNumber();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float Minimum = 0.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float Maximum = 1.0f;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(float InMinimum, float InMaximum);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	float GetMinimum() const { return Minimum; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	float GetMaximum() const { return Maximum; }

	virtual bool ApplyInWorld(const FShockActionContext& Ctx) override;
};
