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
	int32 Opened = 0;
	for (AShockDoor* Door : AShockDoor::CollectByLabel(World, DoorLabel))
	{
		if (Door && Door->OpenDoor(bStayOpen))
		{
			++Opened;
		}
	}
	// Missing label → 0 (not record-only success). Runner still advances either way.
	return Opened;
}

bool UShockActionOpenDoor::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World) > 0;
}
