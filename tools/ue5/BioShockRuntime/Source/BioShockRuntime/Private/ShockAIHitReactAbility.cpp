#include "ShockAIHitReactAbility.h"

#include "BaseShockAI.h"

UShockAIHitReactAbility::UShockAIHitReactAbility()
{
	AchievableGoals.Add(EShockAIGoalType::React);
}

bool UShockAIHitReactAbility::CanAchieve(const UShockAIGoal& Goal, const FShockAIContext& Context) const
{
	if (!Super::CanAchieve(Goal, Context))
	{
		return false;
	}
	const ABaseShockAI* AI = Context.AI;
	return AI && AI->GetHitReactRemaining() > 0.0f;
}

void UShockAIHitReactAbility::Tick(const FShockAIContext& Context)
{
	ABaseShockAI* AI = Context.AI;
	if (!AI)
	{
		Status = EShockAIAbilityStatus::Failed;
		return;
	}

	AI->StopCombatNavChase();
	if (AI->GetHitReactRemaining() <= 0.0f)
	{
		Status = EShockAIAbilityStatus::Succeeded;
		return;
	}
	Status = EShockAIAbilityStatus::Running;
}
