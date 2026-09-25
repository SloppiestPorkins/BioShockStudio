#include "ShockActionLockDoor.h"

#include "ShockDoor.h"

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

int32 UShockActionLockDoor::ApplyInWorld(UWorld* World)
{
	if (!RequestLock() || !World)
	{
		return 0;
	}
	int32 Locked = 0;
	for (AShockDoor* Door : AShockDoor::CollectByLabel(World, DoorLabel))
	{
		if (Door)
		{
			Door->SetLocked(true);
			++Locked;
		}
	}
	return Locked;
}

bool UShockActionLockDoor::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World) > 0;
}
