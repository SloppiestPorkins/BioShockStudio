#include "ShockAIPatrolAbility.h"

#include "BaseShockAI.h"

UShockAIPatrolAbility::UShockAIPatrolAbility()
{
	AchievableGoals.Add(EShockAIGoalType::Patrol);
}

bool UShockAIPatrolAbility::CanAchieve(const UShockAIGoal& Goal, const FShockAIContext& Context) const
{
	return Super::CanAchieve(Goal, Context);
}

void UShockAIPatrolAbility::Tick(const FShockAIContext& Context)
{
	// PLAUSIBLE: patrol route graph not wired — hold position until PatrolName data drives MoveTo.
	(void)Context;
	Status = EShockAIAbilityStatus::Running;
}
