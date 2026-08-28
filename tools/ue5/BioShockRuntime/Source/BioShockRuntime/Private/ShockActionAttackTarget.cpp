#include "ShockActionAttackTarget.h"

#include "BaseShockAI.h"
#include "EngineUtils.h"
#include "GameFramework/Actor.h"
#include "ShockPawn.h"

namespace
{
	bool ActorHasEditorLabel(const AActor* Actor, const FString& Want)
	{
#if WITH_EDITOR
		return Actor && Actor->GetActorLabel().Equals(Want, ESearchCase::CaseSensitive);
#else
		(void)Actor;
		(void)Want;
		return false;
#endif
	}

	bool IsAlivePawn(const AShockPawn* Pawn)
	{
		return Pawn && !Pawn->IsDead() && Pawn->GetCurrentHealth() > 0.0f;
	}

	bool AIMatchesLabel(const ABaseShockAI* AI, const FString& Want)
	{
		if (!AI)
		{
			return false;
		}
		if (ActorHasEditorLabel(AI, Want))
		{
			return true;
		}
		return AI->GetScriptLabel().ToString().Equals(Want, ESearchCase::CaseSensitive);
	}
}

UShockActionAttackTarget::UShockActionAttackTarget()
{
	ActionClassName = TEXT("ActionAttackTarget");
}

void UShockActionAttackTarget::Configure(FName InAILabel, FName InTargetLabel, bool bInAttackOnSight)
{
	AILabel = InAILabel;
	TargetLabel = InTargetLabel;
	bAttackOnSight = bInAttackOnSight;
}

bool UShockActionAttackTarget::RequestAttack()
{
	if (AILabel.IsNone() || TargetLabel.IsNone())
	{
		return false;
	}
	LastRequestedAILabel = AILabel;
	LastRequestedTargetLabel = TargetLabel;
	bLastRequestedOnSight = bAttackOnSight;
	return true;
}

bool UShockActionAttackTarget::ApplyImmediateDamage(AShockPawn* Target, float DamageAmount)
{
	if (!RequestAttack() || !Target || DamageAmount <= 0.0f)
	{
		return false;
	}
	Target->ApplyAuthoredDamage(DamageAmount);
	return true;
}

int32 UShockActionAttackTarget::ApplyInWorld(UWorld* World)
{
	LastAppliedCount = 0;
	if (!RequestAttack() || !World)
	{
		return 0;
	}

	const FString WantTarget = TargetLabel.ToString();
	AShockPawn* Target = nullptr;
	for (TActorIterator<AActor> It(World); It; ++It)
	{
		AActor* Actor = *It;
		if (!ActorHasEditorLabel(Actor, WantTarget))
		{
			continue;
		}
		AShockPawn* Pawn = Cast<AShockPawn>(Actor);
		if (!IsAlivePawn(Pawn))
		{
			continue;
		}
		Target = Pawn;
		break;
	}
	if (!Target)
	{
		return 0;
	}

	const FString WantAI = AILabel.ToString();
	for (TActorIterator<ABaseShockAI> It(World); It; ++It)
	{
		ABaseShockAI* AI = *It;
		if (!AIMatchesLabel(AI, WantAI) || !IsAlivePawn(AI))
		{
			continue;
		}
		if (bAttackOnSight)
		{
			AI->AddTargetToAttackOnSight(TargetLabel);
		}
		else
		{
			AI->ScriptedAttackTarget(Target);
		}
		++LastAppliedCount;
	}
	return LastAppliedCount;
}

bool UShockActionAttackTarget::RequestAttackInWorld(UWorld* World, float DamageAmount)
{
	(void)DamageAmount;
	return ApplyInWorld(World) > 0;
}
