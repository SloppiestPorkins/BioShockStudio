#include "ShockActionAttackTarget.h"

#include "EngineUtils.h"
#include "GameFramework/Actor.h"
#include "ShockPawn.h"

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

bool UShockActionAttackTarget::RequestAttackInWorld(UWorld* World, float DamageAmount)
{
	if (!RequestAttack())
	{
		return false;
	}
	if (!World || TargetLabel.IsNone())
	{
		return true;
	}
	const FString Want = TargetLabel.ToString();
	for (TActorIterator<AActor> It(World); It; ++It)
	{
		AActor* Actor = *It;
		if (!Actor)
		{
			continue;
		}
#if WITH_EDITOR
		if (!Actor->GetActorLabel().Equals(Want, ESearchCase::CaseSensitive))
		{
			continue;
		}
		if (AShockPawn* Pawn = Cast<AShockPawn>(Actor))
		{
			if (DamageAmount > 0.0f)
			{
				Pawn->ApplyAuthoredDamage(DamageAmount);
			}
			break;
		}
#endif
	}
	return true;
}
