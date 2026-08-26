#include "ShockActionApplyImpulse.h"

UShockActionApplyImpulse::UShockActionApplyImpulse()
{
	ActionClassName = TEXT("ActionApplyImpulse");
}

void UShockActionApplyImpulse::Configure(FName InTarget, FVector InVelocity, FName InBone)
{
	Target = InTarget;
	Velocity = InVelocity;
	BoneName = InBone;
}

bool UShockActionApplyImpulse::RequestApply()
{
	if (Target.IsNone())
	{
		return false;
	}
	LastTarget = Target;
	return true;
}
