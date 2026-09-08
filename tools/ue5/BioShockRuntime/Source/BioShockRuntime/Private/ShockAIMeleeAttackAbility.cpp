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

void UShockAIMeleeAttackAbility::Enter(const FShockAIContext& Context)
{
	Super::Enter(Context);
	// The exact native GetAverageAttackAnimationInitiateDamageTime body is unavailable.
	// 0.35 s preserves the authored wind-up-before-damage ordering without claiming byte exactness.
	WindupRemaining = 0.35f;
	bHitCommitted = false;
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
	if (AI->GetMeleeCooldownRemaining() > 0.0f || AI->GetHitReactRemaining() > 0.0f)
	{
		return;
	}
	if (bHitCommitted)
	{
		bHitCommitted = false;
		WindupRemaining = 0.35f;
	}

	if (WindupRemaining > 0.0f)
	{
		WindupRemaining = FMath::Max(0.0f, WindupRemaining - Context.DeltaSeconds);
		const FVector LungeDirection =
			(Target->GetActorLocation() - AI->GetActorLocation()).GetSafeNormal2D();
		AI->AddMovementInput(LungeDirection, 1.0f);
		if (!LungeDirection.IsNearlyZero())
		{
			AI->SetActorLocation(
				AI->GetActorLocation() + LungeDirection * 220.0f * Context.DeltaSeconds,
				true);
		}
		Status = EShockAIAbilityStatus::Running;
		return;
	}

	if (!bHitCommitted)
	{
		UShockDamageLibrary::ApplyDamage(Target, AI->MeleeDamage, AI, FName(TEXT("Melee")));
		AI->SetMeleeCooldownRemaining(AI->MeleeCooldown);
		bHitCommitted = true;
	}
	Status = EShockAIAbilityStatus::Running;
}

void UShockAIMeleeAttackAbility::Exit(const FShockAIContext& Context)
{
	WindupRemaining = 0.0f;
	bHitCommitted = false;
	Super::Exit(Context);
}
