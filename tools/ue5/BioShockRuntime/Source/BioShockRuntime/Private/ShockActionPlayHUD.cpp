#include "ShockActionPlayHUD.h"

#include "ShockPlayer.h"

UShockActionPlayHUD::UShockActionPlayHUD()
{
	ActionClassName = TEXT("ActionPlayHUD");
}

bool UShockActionPlayHUD::RequestPlay()
{
	bPlayRequested = true;
	return true;
}

int32 UShockActionPlayHUD::ApplyInWorld(UWorld* World)
{
	if (!RequestPlay() || !World)
	{
		return 0;
	}
	AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World);
	if (!Player)
	{
		return 0;
	}
	Player->SetHUDPlaying(true);
	return 1;
}
