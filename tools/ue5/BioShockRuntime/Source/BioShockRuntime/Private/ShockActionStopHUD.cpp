#include "ShockActionStopHUD.h"

#include "ShockPlayer.h"

UShockActionStopHUD::UShockActionStopHUD()
{
	ActionClassName = TEXT("ActionStopHUD");
}

bool UShockActionStopHUD::RequestStop()
{
	bStopRequested = true;
	return true;
}

int32 UShockActionStopHUD::ApplyInWorld(UWorld* World)
{
	if (!RequestStop() || !World)
	{
		return 0;
	}
	AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World);
	if (!Player)
	{
		return 0;
	}
	Player->SetHUDPlaying(false);
	return 1;
}
