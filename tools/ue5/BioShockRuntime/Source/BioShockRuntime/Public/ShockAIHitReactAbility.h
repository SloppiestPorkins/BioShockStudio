#pragma once

#include "ShockAIAbility.h"
#include "ShockAIHitReactAbility.generated.h"

UCLASS()
class BIOSHOCKRUNTIME_API UShockAIHitReactAbility : public UShockAIAbility
{
	GENERATED_BODY()

public:
	UShockAIHitReactAbility();

	virtual bool CanAchieve(const UShockAIGoal& Goal, const FShockAIContext& Context) const override;
	virtual void Tick(const FShockAIContext& Context) override;
};
