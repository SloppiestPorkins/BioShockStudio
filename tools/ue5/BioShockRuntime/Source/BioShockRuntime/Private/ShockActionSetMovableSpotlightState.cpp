#include "ShockActionSetMovableSpotlightState.h"

UShockActionSetMovableSpotlightState::UShockActionSetMovableSpotlightState()
{
	ActionClassName = TEXT("ActionSetMovableSpotlightState");
}

void UShockActionSetMovableSpotlightState::Configure(FName InSpotlight, bool bInOn)
{
	SpotlightLabel = InSpotlight;
	bSpotlightOn = bInOn;
}

bool UShockActionSetMovableSpotlightState::RequestSetState()
{
	if (SpotlightLabel.IsNone())
	{
		return false;
	}
	LastSpotlightLabel = SpotlightLabel;
	return true;
}
