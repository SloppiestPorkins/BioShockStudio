#include "ShockActionSetHUDDisplayState.h"

#include "ShockPlayer.h"

UShockActionSetHUDDisplayState::UShockActionSetHUDDisplayState()
{
	ActionClassName = TEXT("ActionSetHUDDisplayState");
}

void UShockActionSetHUDDisplayState::Configure(bool bInEnable)
{
	bEnableHUD = bInEnable;
}

bool UShockActionSetHUDDisplayState::RequestSet()
{
	bLastEnableHUD = bEnableHUD;
	return true;
}

int32 UShockActionSetHUDDisplayState::ApplyInWorld(UWorld* World)
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
	Player->SetHUDEnabled(bEnableHUD);
	return 1;
}

bool UShockActionSetHUDDisplayState::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World) > 0;
}
