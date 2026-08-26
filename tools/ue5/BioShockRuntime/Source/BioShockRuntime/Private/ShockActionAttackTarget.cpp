#include "ShockActionAttackTarget.h"

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
