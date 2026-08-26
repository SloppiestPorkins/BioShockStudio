#include "ShockActionSetMovableSpotlightTarget.h"

UShockActionSetMovableSpotlightTarget::UShockActionSetMovableSpotlightTarget()
{
	ActionClassName = TEXT("ActionSetMovableSpotlightTarget");
}

void UShockActionSetMovableSpotlightTarget::Configure(FName InSpotlight, FName InTarget)
{
	SpotlightLabel = InSpotlight;
	TargetActorLabel = InTarget;
}

bool UShockActionSetMovableSpotlightTarget::RequestSetTarget()
{
	if (SpotlightLabel.IsNone())
	{
		return false;
	}
	LastSpotlightLabel = SpotlightLabel;
	LastTargetActorLabel = TargetActorLabel;
	return true;
}
