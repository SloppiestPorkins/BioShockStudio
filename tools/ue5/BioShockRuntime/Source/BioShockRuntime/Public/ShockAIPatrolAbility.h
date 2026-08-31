#pragma once

#include "ShockAIAbility.h"
#include "ShockAIPatrolAbility.generated.h"

/** PLAUSIBLE patrol stub — full patrol graph deferred until level patrol data is wired. */
UCLASS()
class BIOSHOCKRUNTIME_API UShockAIPatrolAbility : public UShockAIAbility
{
	GENERATED_BODY()

public:
	UShockAIPatrolAbility();

	virtual bool CanAchieve(const UShockAIGoal& Goal, const FShockAIContext& Context) const override;
	virtual void Tick(const FShockAIContext& Context) override;
};
