#include "ShockActionTriggerHavokForceActor.h"

UShockActionTriggerHavokForceActor::UShockActionTriggerHavokForceActor()
{
	ActionClassName = TEXT("ActionTriggerHavokForceActor");
}

void UShockActionTriggerHavokForceActor::Configure(FName InTarget)
{
	TargetLabel = InTarget;
}

bool UShockActionTriggerHavokForceActor::RequestTrigger()
{
	if (TargetLabel.IsNone())
	{
		return false;
	}
	LastTargetLabel = TargetLabel;
	return true;
}
