#include "ShockActionCloseDoor.h"

UShockActionCloseDoor::UShockActionCloseDoor()
{
	ActionClassName = TEXT("ActionCloseDoor");
	DoorLabel = TEXT("UNSPECIFIED");
}

void UShockActionCloseDoor::Configure(FName InDoorLabel, bool bInForceClose)
{
	DoorLabel = InDoorLabel;
	bForceClose = bInForceClose;
}

bool UShockActionCloseDoor::RequestClose()
{
	if (DoorLabel.IsNone() || DoorLabel == FName(TEXT("UNSPECIFIED")))
	{
		return false;
	}
	LastClosedDoorLabel = DoorLabel;
	return true;
}
