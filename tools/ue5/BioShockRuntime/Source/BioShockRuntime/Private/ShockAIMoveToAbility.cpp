#include "ShockAIMoveToAbility.h"

#include "BaseShockAI.h"
#include "ShockPawn.h"

UShockAIMoveToAbility::UShockAIMoveToAbility()
{
	AchievableGoals.Add(EShockAIGoalType::KillTarget);
	AchievableGoals.Add(EShockAIGoalType::MoveTo);
}

bool UShockAIMoveToAbility::CanAchieve(const UShockAIGoal& Goal, const FShockAIContext& Context) const
{
	if (!Super::CanAchieve(Goal, Context))
	{
		return false;
	}

	const ABaseShockAI* AI = Context.AI;
	if (!AI)
	{
		return false;
	}

	AShockPawn* Target = Cast<AShockPawn>(Goal.TargetActor);
	if (Goal.GoalType == EShockAIGoalType::KillTarget)
	{
		if (!AI->IsAliveCombatTarget(Target))
		{
			Target = AI->GetCombatTargetPawn();
		}
		if (!AI->IsAliveCombatTarget(Target))
		{
			return false;
		}
		const float Dist = AI->GetDistanceToCombatTarget(Target);
		if (Dist <= AI->MeleeRange)
		{
			return false;
		}
		if (AI->HasAIWeapon() && Dist <= AI->RangedRange && Dist > AI->MeleeRange
			&& AI->HasCombatLineOfSightTo(Target))
		{
			return false;
		}
		return true;
	}

	return true;
}

void UShockAIMoveToAbility::Tick(const FShockAIContext& Context)
{
	ABaseShockAI* AI = Context.AI;
	if (!AI || !Context.Goal)
	{
		Status = EShockAIAbilityStatus::Failed;
		return;
	}

	AShockPawn* Target = Cast<AShockPawn>(Context.Goal->TargetActor);
	if (Context.Goal->GoalType == EShockAIGoalType::KillTarget)
	{
		if (!AI->IsAliveCombatTarget(Target))
		{
			Target = AI->GetCombatTargetPawn();
		}
		if (!AI->IsAliveCombatTarget(Target))
		{
			AI->StopCombatNavChase();
			Status = EShockAIAbilityStatus::Failed;
			return;
		}

		AI->SetCombatTargetPawn(Target);

		const float Dist = AI->GetDistanceToCombatTarget(Target);
		// Last-known-position memory is owned by ABaseShockAI's high-level state machine.
		// Do not reset its hidden-target timer merely because the target remains nearby.

		if (Dist <= AI->MeleeRange)
		{
			AI->StopCombatNavChase();
			Status = EShockAIAbilityStatus::Succeeded;
			return;
		}

		if (AI->HasAIWeapon() && Dist <= AI->RangedRange && Dist > AI->MeleeRange
			&& AI->HasCombatLineOfSightTo(Target))
		{
			AI->StopCombatNavChase();
			Status = EShockAIAbilityStatus::Succeeded;
			return;
		}

		AI->FaceCombatTarget(Target);
		if (!AI->TryTickCombatNavChase(Target, Context.DeltaSeconds))
		{
			AI->TickCombatChaseDirectMovement(Target, Context.DeltaSeconds);
		}
		Status = EShockAIAbilityStatus::Running;
		return;
	}

	Status = EShockAIAbilityStatus::Running;
}
