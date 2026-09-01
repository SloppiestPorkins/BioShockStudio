#include "ShockAIBrain.h"

#include "BaseShockAI.h"
#include "ShockPawn.h"
#include "ShockAIFleeAbility.h"
#include "ShockAIHitReactAbility.h"
#include "ShockAIIdleAbility.h"
#include "ShockAIMeleeAttackAbility.h"
#include "ShockAIMoveToAbility.h"
#include "ShockAIPatrolAbility.h"
#include "ShockAIRangedAttackAbility.h"
#include "ShockPawn.h"

UShockAIBrain::UShockAIBrain()
{
	PrimaryComponentTick.bCanEverTick = false;
}

EShockAIGoalType UShockAIBrain::GetActiveGoalType() const
{
	return ActiveGoal ? ActiveGoal->GoalType : EShockAIGoalType::Idle;
}

FName UShockAIBrain::GetActiveAbilityName() const
{
	return ActiveAbility ? ActiveAbility->GetClass()->GetFName() : NAME_None;
}

void UShockAIBrain::InitializeForAI(ABaseShockAI* AI)
{
	if (!AI)
	{
		return;
	}
	if (Abilities.Num() == 0)
	{
		SeedDefaultAbilities(AI);
		return;
	}

	if (!AI->HasAIWeapon())
	{
		return;
	}

	for (const UShockAIAbility* Ability : Abilities)
	{
		if (Ability && Ability->IsA<UShockAIRangedAttackAbility>())
		{
			return;
		}
	}

	int32 InsertAt = 3;
	Abilities.Insert(NewObject<UShockAIRangedAttackAbility>(this), InsertAt);
}

void UShockAIBrain::SeedDefaultAbilities(ABaseShockAI* AI)
{
	Abilities.Add(NewObject<UShockAIHitReactAbility>(this));
	Abilities.Add(NewObject<UShockAIFleeAbility>(this));
	Abilities.Add(NewObject<UShockAIMeleeAttackAbility>(this));
	Abilities.Add(NewObject<UShockAIRangedAttackAbility>(this));
	Abilities.Add(NewObject<UShockAIMoveToAbility>(this));
	Abilities.Add(NewObject<UShockAIPatrolAbility>(this));
	Abilities.Add(NewObject<UShockAIIdleAbility>(this));

	if (AI && !AI->HasAIWeapon())
	{
		Abilities.RemoveAll(
			[](const UShockAIAbility* Ability)
			{
				return Ability && Ability->IsA<UShockAIRangedAttackAbility>();
			});
	}
}

void UShockAIBrain::NotifyAggro(AShockPawn* Instigator)
{
	NotifyPendingKillTarget(Instigator);
}

void UShockAIBrain::NotifyPendingKillTarget(AShockPawn* Target)
{
	if (Target)
	{
		PendingKillTarget = Target;
	}
}

UShockAIGoal* UShockAIBrain::MakeGoal(
	EShockAIGoalType Type,
	float Priority,
	AActor* TargetActor)
{
	UShockAIGoal* Goal = NewObject<UShockAIGoal>(this);
	Goal->GoalType = Type;
	Goal->Priority = Priority;
	Goal->TargetActor = TargetActor;
	return Goal;
}

TArray<UShockAIGoal*> UShockAIBrain::BuildCandidateGoals(ABaseShockAI* AI, float DeltaSeconds)
{
	TArray<UShockAIGoal*> Goals;
	if (!AI)
	{
		return Goals;
	}

	if (AI->GetHitReactRemaining() > 0.0f)
	{
		Goals.Add(MakeGoal(EShockAIGoalType::React, 150.0f));
	}

	const float MaxHealth = AI->AuthoredMaxHealth > 0.0f
		? AI->AuthoredMaxHealth
		: FMath::Max(AI->CurrentHealth, 100.0f);
	if (MaxHealth > 0.0f && (AI->CurrentHealth / MaxHealth) <= FleeHealthFraction)
	{
		Goals.Add(MakeGoal(EShockAIGoalType::Flee, 120.0f));
	}

	if (AI->IsEnraged())
	{
		if (AShockPawn* EnrageTarget = AI->FindNearestOtherAIForEnrage())
		{
			AI->SetCombatTargetPawn(EnrageTarget);
			Goals.Add(MakeGoal(EShockAIGoalType::KillTarget, 100.0f, EnrageTarget));
		}
		Goals.Add(MakeGoal(EShockAIGoalType::Patrol, 10.0f));
		Goals.Add(MakeGoal(EShockAIGoalType::Idle, 0.0f));
		Goals.Sort(
			[](const UShockAIGoal& A, const UShockAIGoal& B)
			{
				return A.Priority > B.Priority;
			});
		return Goals;
	}

	AShockPawn* KillTarget = nullptr;
	if (PendingKillTarget.IsValid() && AI->IsAliveCombatTarget(PendingKillTarget.Get()))
	{
		KillTarget = PendingKillTarget.Get();
		AI->SetCombatTargetPawn(KillTarget);
		PendingKillTarget.Reset();
	}
	else if (AI->IsAliveCombatTarget(AI->GetCurrentScriptedAttackTargetPawn()))
	{
		KillTarget = AI->GetCurrentScriptedAttackTargetPawn();
		AI->SetCombatTargetPawn(KillTarget);
	}
	else if (AI->IsAliveCombatTarget(AI->GetCombatTargetPawn()))
	{
		KillTarget = AI->GetCombatTargetPawn();
	}
	else
	{
		AI->TickBrainIdlePerception(DeltaSeconds);
		if (AI->IsAliveCombatTarget(AI->GetCombatTargetPawn()))
		{
			KillTarget = AI->GetCombatTargetPawn();
		}
	}

	if (KillTarget)
	{
		Goals.Add(MakeGoal(EShockAIGoalType::KillTarget, 100.0f, KillTarget));
	}

	if (!KillTarget)
	{
		Goals.Add(MakeGoal(EShockAIGoalType::Patrol, 10.0f));
	}

	Goals.Add(MakeGoal(EShockAIGoalType::Idle, 0.0f));

	Goals.Sort(
		[](const UShockAIGoal& A, const UShockAIGoal& B)
		{
			return A.Priority > B.Priority;
		});

	return Goals;
}

UShockAIAbility* UShockAIBrain::FindAbilityForGoal(
	const UShockAIGoal& Goal,
	const FShockAIContext& Context) const
{
	for (UShockAIAbility* Ability : Abilities)
	{
		if (Ability && Ability->CanAchieve(Goal, Context))
		{
			return Ability;
		}
	}
	return nullptr;
}

void UShockAIBrain::SwitchAbility(
	UShockAIAbility* NewAbility,
	UShockAIGoal* NewGoal,
	const FShockAIContext& Context)
{
	if (ActiveAbility == NewAbility && ActiveGoal && NewGoal
		&& ActiveGoal->GoalType == NewGoal->GoalType
		&& ActiveGoal->TargetActor == NewGoal->TargetActor)
	{
		return;
	}

	if (ActiveAbility)
	{
		ActiveAbility->Exit(Context);
	}

	ActiveAbility = NewAbility;
	ActiveGoal = NewGoal;

	if (ActiveAbility)
	{
		ActiveAbility->Enter(Context);
	}
}

void UShockAIBrain::Think(float DeltaSeconds)
{
	ABaseShockAI* AI = Cast<ABaseShockAI>(GetOwner());
	if (!AI || Abilities.Num() == 0)
	{
		return;
	}

	FShockAIContext Context;
	Context.AI = AI;
	Context.DeltaSeconds = DeltaSeconds;

	ThinkAccumulator += DeltaSeconds;
	const bool bHitReactActive = AI->GetHitReactRemaining() > 0.0f;
	const bool bShouldReevaluate = ThinkAccumulator >= ThinkInterval || !ActiveAbility
		|| (bHitReactActive && (!ActiveGoal || ActiveGoal->GoalType != EShockAIGoalType::React));
	if (bShouldReevaluate)
	{
		ThinkAccumulator = 0.0f;

		TArray<UShockAIGoal*> Candidates = BuildCandidateGoals(AI, DeltaSeconds);
		UShockAIGoal* ChosenGoal = nullptr;
		UShockAIAbility* ChosenAbility = nullptr;

		for (UShockAIGoal* Candidate : Candidates)
		{
			if (!Candidate)
			{
				continue;
			}
			Context.Goal = Candidate;
			UShockAIAbility* Ability = FindAbilityForGoal(*Candidate, Context);
			if (Ability)
			{
				ChosenGoal = Candidate;
				ChosenAbility = Ability;
				break;
			}
		}

		if (ChosenAbility && ChosenGoal)
		{
			Context.Goal = ChosenGoal;
			SwitchAbility(ChosenAbility, ChosenGoal, Context);
		}
	}

	if (ActiveAbility && ActiveGoal)
	{
		Context.Goal = ActiveGoal;
		ActiveAbility->Tick(Context);
	}
}
