#pragma once

#include "ShockAIAbility.h"
#include "ShockAIFleeAbility.generated.h"

/** PLAUSIBLE flee stub — full flee nav deferred until ecology flee targets exist. */
UCLASS()
class BIOSHOCKRUNTIME_API UShockAIFleeAbility : public UShockAIAbility
{
	GENERATED_BODY()

public:
	UShockAIFleeAbility();

	virtual bool CanAchieve(const UShockAIGoal& Goal, const FShockAIContext& Context) const override;
	virtual void Tick(const FShockAIContext& Context) override;
};
