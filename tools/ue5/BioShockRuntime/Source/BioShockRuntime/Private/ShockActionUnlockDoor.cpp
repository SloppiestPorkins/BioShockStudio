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
	if (AShockDoor* Door = AShockDoor::FindByLabel(World, DoorLabel))
	{
		Door->SetLocked(false);
	}
	return 1;
}

bool UShockActionUnlockDoor::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World) > 0;
}
