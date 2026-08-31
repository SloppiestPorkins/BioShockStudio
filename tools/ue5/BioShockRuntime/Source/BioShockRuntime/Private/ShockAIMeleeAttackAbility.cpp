#include "ShockAIMeleeAttackAbility.h"

#include "BaseShockAI.h"
#include "ShockDamageLibrary.h"
#include "ShockPawn.h"

UShockAIMeleeAttackAbility::UShockAIMeleeAttackAbility()
{
	AchievableGoals.Add(EShockAIGoalType::KillTarget);
}

bool UShockAIMeleeAttackAbility::CanAchieve(const UShockAIGoal& Goal, const FShockAIContext& Context) const
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
	if (!AI->IsAliveCombatTarget(Target))
	{
		Target = AI->GetCombatTargetPawn();
	}
	if (!AI->IsAliveCombatTarget(Target))
	{
		return false;
	}
	return AI->GetDistanceToCombatTarget(Target) <= AI->MeleeRange;
}

void UShockAIMeleeAttackAbility::Tick(const FShockAIContext& Context)
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
	if (Dist > AI->MeleeRange)
	{
		Status = EShockAIAbilityStatus::Succeeded;
		return;
	}

	AI->FaceCombatTarget(Target);
	if (AI->GetMeleeCooldownRemaining() <= 0.0f && AI->GetHitReactRemaining() <= 0.0f)
	{
		UShockDamageLibrary::ApplyDamage(Target, AI->MeleeDamage, AI, FName(TEXT("Melee")));
		AI->SetMeleeCooldownRemaining(AI->MeleeCooldown);
	}
	Status = EShockAIAbilityStatus::Running;
}
