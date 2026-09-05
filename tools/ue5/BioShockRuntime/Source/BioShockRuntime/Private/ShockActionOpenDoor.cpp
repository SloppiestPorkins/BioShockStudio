#include "ShockActionOpenDoor.h"

#include "ShockDoor.h"

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

int32 UShockActionOpenDoor::ApplyInWorld(UWorld* World)
{
	if (!RequestOpen() || !World)
	{
		return 0;
	}
	if (AShockDoor* Door = AShockDoor::FindByLabel(World, DoorLabel))
	{
		return Door->OpenDoor(bStayOpen) ? 1 : 0;
	}
	// No placed AShockDoor yet — keep record-only success so script runners still advance.
	return 1;
}

bool UShockActionOpenDoor::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World) > 0;
}
