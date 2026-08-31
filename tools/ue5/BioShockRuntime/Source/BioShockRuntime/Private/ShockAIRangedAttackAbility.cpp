#include "ShockAIRangedAttackAbility.h"

#include "BaseShockAI.h"
#include "ShockPawn.h"

UShockAIRangedAttackAbility::UShockAIRangedAttackAbility()
{
	AchievableGoals.Add(EShockAIGoalType::KillTarget);
}

bool UShockAIRangedAttackAbility::CanAchieve(const UShockAIGoal& Goal, const FShockAIContext& Context) const
{
	if (!Super::CanAchieve(Goal, Context))
	{
		return false;
	}

	const ABaseShockAI* AI = Context.AI;
	if (!AI || !AI->HasAIWeapon())
	{
		return false;
	}

	AShockPawn* Target = Cast<AShockPawn>(Goal.TargetActor);
	if (!AI->IsAliveCombatTarget(Target))
	{
		Target = AI->GetCombatTargetPawn();
	}
	if (!AI->IsAliveCombatTarget(Target))
	{
		return false;
	}

	const float Dist = AI->GetDistanceToCombatTarget(Target);
	return Dist <= AI->RangedRange && Dist > AI->MeleeRange && AI->HasCombatLineOfSightTo(Target);
}

void UShockAIRangedAttackAbility::Tick(const FShockAIContext& Context)
{
	ABaseShockAI* AI = Context.AI;
	if (!AI)
	{
		Status = EShockAIAbilityStatus::Failed;
		return;
	}

	AShockPawn* Target = AI->GetCombatTargetPawn();
	if (!AI->IsAliveCombatTarget(Target))
	{
		AI->StopCombatNavChase();
		AI->ClearCombatTargetPawn();
		Status = EShockAIAbilityStatus::Failed;
		return;
	}

	const float Dist = AI->GetDistanceToCombatTarget(Target);
	if (Dist <= AI->MeleeRange)
	{
		AI->StopCombatNavChase();
		Status = EShockAIAbilityStatus::Succeeded;
		return;
	}
	if (Dist > AI->RangedRange || !AI->HasCombatLineOfSightTo(Target))
	{
		Status = EShockAIAbilityStatus::Succeeded;
		return;
	}

	AI->FaceCombatTarget(Target);
	if (AI->GetRangedCooldownRemaining() <= 0.0f && AI->GetHitReactRemaining() <= 0.0f)
	{
		AI->TryCombatRangedFire();
		AI->SetRangedCooldownRemaining(AI->RangedCooldown);
	}
	Status = EShockAIAbilityStatus::Running;
}
