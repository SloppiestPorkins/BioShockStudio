#include "ShockActionChangeAnimationRate.h"

UShockActionChangeAnimationRate::UShockActionChangeAnimationRate()
{
	ActionClassName = TEXT("ActionChangeAnimationRate");
	TargetLabel = TEXT("UNSPECIFIED");
	TargetAnimationRate = 1.0f;
}

void UShockActionChangeAnimationRate::Configure(FName InTarget, FName InAnim, float InRate, float InTime)
{
	TargetLabel = InTarget;
	TargetAnimationName = InAnim;
	TargetAnimationRate = InRate;
	RateChangeTime = InTime;
}

bool UShockActionChangeAnimationRate::RequestChange()
{
	if (TargetLabel.IsNone())
	{
		return false;
	}
	LastTargetLabel = TargetLabel;
	return true;
}
