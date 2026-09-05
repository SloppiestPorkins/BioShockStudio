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
	if (AShockDoor* Door = AShockDoor::FindByLabel(World, DoorLabel))
	{
		Door->SetLocked(true);
	}
	return 1;
}

bool UShockActionLockDoor::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World) > 0;
}
