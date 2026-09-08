#pragma once

#include "ShockAIAbility.h"
#include "ShockAIMeleeAttackAbility.generated.h"

UCLASS()
class BIOSHOCKRUNTIME_API UShockAIMeleeAttackAbility : public UShockAIAbility
{
	GENERATED_BODY()

public:
	UShockAIMeleeAttackAbility();

	virtual bool CanAchieve(const UShockAIGoal& Goal, const FShockAIContext& Context) const override;
	virtual void Enter(const FShockAIContext& Context) override;
	virtual void Tick(const FShockAIContext& Context) override;
	virtual void Exit(const FShockAIContext& Context) override;

private:
	float WindupRemaining = 0.0f;
	bool bHitCommitted = false;
};
