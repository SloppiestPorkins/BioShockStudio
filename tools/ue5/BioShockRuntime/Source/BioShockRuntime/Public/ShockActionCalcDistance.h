#pragma once

#include "ShockAction.h"
#include "ShockActionCalcDistance.generated.h"

/** Scripting.ActionCalcDistance: returns VariableFloat(distance(actorOne, actorTwo)). */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionCalcDistance : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionCalcDistance();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName ActorOne;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName ActorTwo;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InActorOne, FName InActorTwo);

	virtual bool ApplyInWorld(const FShockActionContext& Ctx) override;
};
