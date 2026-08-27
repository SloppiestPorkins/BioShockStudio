#include "ShockActionSetDoorBrokenState.h"

UShockActionSetDoorBrokenState::UShockActionSetDoorBrokenState()
{
	ActionClassName = TEXT("ActionSetDoorBrokenState");
}

void UShockActionSetDoorBrokenState::Configure(FName InDoor, bool bInBroken)
{
	DoorLabel = InDoor;
	bIsBroken = bInBroken;
}

bool UShockActionSetDoorBrokenState::RequestSet()
{
	if (DoorLabel.IsNone())
	{
		return false;
	}
	LastDoorLabel = DoorLabel;
	return true;
}
