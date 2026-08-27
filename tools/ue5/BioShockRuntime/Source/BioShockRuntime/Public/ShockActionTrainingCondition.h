#pragma once

#include "ShockAction.h"
#include "ShockActionTrainingCondition.generated.h"

/** UnrealScript `TrainingCondition`. Nested tests/actions deferred; params only. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionTrainingCondition : public UShockAction
{
	GENERATED_BODY()
public:
	UShockActionTrainingCondition();
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float Weight = 0.f;
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 TickDelay = 10;
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 Priority = 0;
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName ConceptName;
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bConditionRequested = false;
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(float InWeight, int32 InTickDelay, int32 InPriority, FName InConcept);
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 GetTickDelay() const { return TickDelay; }
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestEvaluate();
};
