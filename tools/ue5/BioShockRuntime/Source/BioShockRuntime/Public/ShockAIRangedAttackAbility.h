#pragma once

#include "ShockAIAbility.h"
#include "ShockAIRangedAttackAbility.generated.h"

UCLASS()
class BIOSHOCKRUNTIME_API UShockAIRangedAttackAbility : public UShockAIAbility
{
	GENERATED_BODY()

public:
	UShockAIRangedAttackAbility();

	virtual bool CanAchieve(const UShockAIGoal& Goal, const FShockAIContext& Context) const override;
	virtual void Tick(const FShockAIContext& Context) override;
};
