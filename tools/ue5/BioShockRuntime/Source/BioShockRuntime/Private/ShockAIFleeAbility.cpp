#include "ShockAIFleeAbility.h"

#include "BaseShockAI.h"

UShockAIFleeAbility::UShockAIFleeAbility()
{
	AchievableGoals.Add(EShockAIGoalType::Flee);
}

bool UShockAIFleeAbility::CanAchieve(const UShockAIGoal& Goal, const FShockAIContext& Context) const
{
	return Super::CanAchieve(Goal, Context);
}

void UShockAIFleeAbility::Tick(const FShockAIContext& Context)
{
	// PLAUSIBLE: flee destination selection deferred — stop attacking for now.
	ABaseShockAI* AI = Context.AI;
	if (AI)
	{
		AI->StopCombatNavChase();
	}
	Status = EShockAIAbilityStatus::Running;
}
