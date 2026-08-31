#include "ShockAIAbility.h"

#include "BaseShockAI.h"

bool UShockAIAbility::CanAchieve(const UShockAIGoal& Goal, const FShockAIContext& Context) const
{
	return AchievableGoals.Contains(Goal.GoalType);
}

void UShockAIAbility::Enter(const FShockAIContext& Context)
{
	Status = EShockAIAbilityStatus::Running;
	OwnerAI = Context.AI;
}

void UShockAIAbility::Tick(const FShockAIContext& Context)
{
	(void)Context;
}

void UShockAIAbility::Exit(const FShockAIContext& Context)
{
	(void)Context;
	OwnerAI = nullptr;
}
