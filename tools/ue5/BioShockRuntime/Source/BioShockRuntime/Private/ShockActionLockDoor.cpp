#include "ShockActionLockDoor.h"

UShockActionLockDoor::UShockActionLockDoor()
{
	ActionClassName = TEXT("ActionLockDoor");
}

void UShockActionLockDoor::Configure(FName InDoorLabel)
{
	DoorLabel = InDoorLabel;
}

bool UShockActionLockDoor::RequestLock()
{
	if (DoorLabel.IsNone())
	{
		return false;
	}
	LastLockedDoorLabel = DoorLabel;
	return true;
}
