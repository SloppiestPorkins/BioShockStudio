#pragma once

#include "ShockAIAbility.h"
#include "ShockAIMoveToAbility.generated.h"

UCLASS()
class BIOSHOCKRUNTIME_API UShockAIMoveToAbility : public UShockAIAbility
{
	GENERATED_BODY()

public:
	UShockAIMoveToAbility();

	virtual bool CanAchieve(const UShockAIGoal& Goal, const FShockAIContext& Context) const override;
	virtual void Tick(const FShockAIContext& Context) override;
};
