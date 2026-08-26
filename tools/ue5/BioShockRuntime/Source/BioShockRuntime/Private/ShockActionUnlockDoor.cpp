#include "ShockActionUnlockDoor.h"

UShockActionUnlockDoor::UShockActionUnlockDoor()
{
	ActionClassName = TEXT("ActionUnlockDoor");
}

void UShockActionUnlockDoor::Configure(FName InDoorLabel)
{
	DoorLabel = InDoorLabel;
}

bool UShockActionUnlockDoor::RequestUnlock()
{
	if (DoorLabel.IsNone())
	{
		return false;
	}
	LastUnlockedDoorLabel = DoorLabel;
	return true;
}
