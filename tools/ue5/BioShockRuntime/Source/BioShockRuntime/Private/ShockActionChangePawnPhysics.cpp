#include "ShockActionChangePawnPhysics.h"

UShockActionChangePawnPhysics::UShockActionChangePawnPhysics()
{
	ActionClassName = TEXT("ActionChangePawnPhysics");
}

void UShockActionChangePawnPhysics::Configure(FName InTarget, bool bInDisable, bool bInRootMotion)
{
	TargetLabel = InTarget;
	bDisablePhysics = bInDisable;
	bEnableRootMotionWhenPhysicsDisabled = bInRootMotion;
}

bool UShockActionChangePawnPhysics::RequestChange()
{
	if (TargetLabel.IsNone())
	{
		return false;
	}
	LastTargetLabel = TargetLabel;
	return true;
}
