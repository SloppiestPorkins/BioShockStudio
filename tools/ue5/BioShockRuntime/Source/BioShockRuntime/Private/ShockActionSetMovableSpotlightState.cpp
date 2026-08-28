#include "ShockActionSetMovableSpotlightState.h"

#include "ShockPlayer.h"

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

int32 UShockActionSetMovableSpotlightState::ApplyInWorld(UWorld* World)
{
	if (!RequestSetState() || !World)
	{
		return 0;
	}
	AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World);
	if (!Player)
	{
		return 0;
	}
	Player->SetSpotlightOn(SpotlightLabel, bSpotlightOn);
	return 1;
}
