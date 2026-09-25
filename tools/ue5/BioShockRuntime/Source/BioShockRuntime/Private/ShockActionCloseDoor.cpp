#include "ShockActionCloseDoor.h"

#include "ShockDoor.h"

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

int32 UShockActionCloseDoor::ApplyInWorld(UWorld* World)
{
	if (!RequestClose() || !World)
	{
		return 0;
	}
	int32 Closed = 0;
	for (AShockDoor* Door : AShockDoor::CollectByLabel(World, DoorLabel))
	{
		if (Door && Door->CloseDoor(bForceClose))
		{
			++Closed;
		}
	}
	return Closed;
}

bool UShockActionCloseDoor::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World) > 0;
}
