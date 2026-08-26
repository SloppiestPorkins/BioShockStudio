#include "ShockActionRagdoll.h"

UShockActionRagdoll::UShockActionRagdoll()
{
	ActionClassName = TEXT("ActionRagdoll");
}

void UShockActionRagdoll::Configure(FName InAI, bool bInRelative, FVector InImpulse, float InMomentum)
{
	AILabel = InAI;
	bRelativeToAIRotation = bInRelative;
	HitImpulseDirection = InImpulse;
	HitMomentumImparted = InMomentum;
}

bool UShockActionRagdoll::RequestRagdoll()
{
	if (AILabel.IsNone())
	{
		return false;
	}
	LastAILabel = AILabel;
	return true;
}
