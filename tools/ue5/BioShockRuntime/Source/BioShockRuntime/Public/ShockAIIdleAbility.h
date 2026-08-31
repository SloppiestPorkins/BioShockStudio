#pragma once

#include "ShockAIAbility.h"
#include "ShockAIIdleAbility.generated.h"

UCLASS()
class BIOSHOCKRUNTIME_API UShockAIIdleAbility : public UShockAIAbility
{
	GENERATED_BODY()

public:
	UShockAIIdleAbility();

	virtual bool CanAchieve(const UShockAIGoal& Goal, const FShockAIContext& Context) const override;
	virtual void Tick(const FShockAIContext& Context) override;
};
