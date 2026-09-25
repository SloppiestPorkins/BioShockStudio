#include "ShockActionUnlockDoor.h"

#include "ShockDoor.h"

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

int32 UShockActionUnlockDoor::ApplyInWorld(UWorld* World)
{
	if (!RequestUnlock() || !World)
	{
		return 0;
	}
	int32 Unlocked = 0;
	for (AShockDoor* Door : AShockDoor::CollectByLabel(World, DoorLabel))
	{
		if (Door)
		{
			Door->SetLocked(false);
			++Unlocked;
		}
	}
	return Unlocked;
}

bool UShockActionUnlockDoor::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World) > 0;
}
