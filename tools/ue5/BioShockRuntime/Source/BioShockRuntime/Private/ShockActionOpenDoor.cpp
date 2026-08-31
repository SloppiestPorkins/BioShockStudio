#include "ShockActionOpenDoor.h"

UShockActionOpenDoor::UShockActionOpenDoor()
{
	ActionClassName = TEXT("ActionOpenDoor");
}

void UShockActionOpenDoor::Configure(FName InDoorLabel, bool bInStayOpen)
{
	DoorLabel = InDoorLabel;
	bStayOpen = bInStayOpen;
}

bool UShockActionOpenDoor::RequestOpen()
{
	if (DoorLabel.IsNone())
	{
		return false;
	}
	LastOpenedDoorLabel = DoorLabel;
	return true;
}

bool UShockActionOpenDoor::ApplyInWorld(const FShockActionContext& Ctx)
{
	return RequestOpen();
}
