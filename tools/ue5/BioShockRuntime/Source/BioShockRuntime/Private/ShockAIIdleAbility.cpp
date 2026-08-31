#include "ShockAIIdleAbility.h"

#include "BaseShockAI.h"

UShockAIIdleAbility::UShockAIIdleAbility()
{
	AchievableGoals.Add(EShockAIGoalType::Idle);
}

bool UShockAIIdleAbility::CanAchieve(const UShockAIGoal& Goal, const FShockAIContext& Context) const
{
	return Super::CanAchieve(Goal, Context);
}

void UShockAIIdleAbility::Tick(const FShockAIContext& Context)
{
	ABaseShockAI* AI = Context.AI;
	if (!AI)
	{
		return;
	}
	AI->StopCombatNavChase();
	Status = EShockAIAbilityStatus::Running;
}
