#include "ShockActionSetDoorBrokenState.h"

#include "ShockPlayer.h"

UShockActionSetDoorBrokenState::UShockActionSetDoorBrokenState()
{
	ActionClassName = TEXT("ActionSetDoorBrokenState");
}

void UShockActionSetDoorBrokenState::Configure(FName InDoor, bool bInBroken)
{
	DoorLabel = InDoor;
	bIsBroken = bInBroken;
}

bool UShockActionSetDoorBrokenState::RequestSet()
{
	if (DoorLabel.IsNone())
	{
		return false;
	}
	LastDoorLabel = DoorLabel;
	return true;
}

int32 UShockActionSetDoorBrokenState::ApplyInWorld(UWorld* World)
{
	if (!RequestSet() || !World)
	{
		return 0;
	}
	AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World);
	if (!Player)
	{
		return 0;
	}
	Player->SetDoorBroken(DoorLabel, bIsBroken);
	return 1;
}

bool UShockActionSetDoorBrokenState::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World) > 0;
}
