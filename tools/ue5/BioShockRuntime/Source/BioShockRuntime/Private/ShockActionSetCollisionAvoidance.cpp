#include "ShockActionSetCollisionAvoidance.h"

UShockActionSetCollisionAvoidance::UShockActionSetCollisionAvoidance()
{
	ActionClassName = TEXT("ActionSetCollisionAvoidance");
}

void UShockActionSetCollisionAvoidance::Configure(FName InAILabel, bool bInUse)
{
	AILabel = InAILabel;
	bShouldUseCollisionAvoidance = bInUse;
}

bool UShockActionSetCollisionAvoidance::RequestSet()
{
	if (AILabel.IsNone())
	{
		return false;
	}
	LastAILabel = AILabel;
	return true;
}
