#include "ShockActionDisableOrEnableResurrectionStation.h"

#include "ShockPlayer.h"

UShockActionDisableOrEnableResurrectionStation::UShockActionDisableOrEnableResurrectionStation()
{
	ActionClassName = TEXT("ActionDisableOrEnableResurrectionStation");
}

void UShockActionDisableOrEnableResurrectionStation::Configure(FName InStation, bool bInEnable)
{
	StationLabel = InStation;
	bEnable = bInEnable;
}

bool UShockActionDisableOrEnableResurrectionStation::RequestSet()
{
	if (StationLabel.IsNone())
	{
		return false;
	}
	LastStationLabel = StationLabel;
	return true;
}

int32 UShockActionDisableOrEnableResurrectionStation::ApplyInWorld(UWorld* World)
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
	Player->SetResurrectionStationEnabled(StationLabel, bEnable);
	return 1;
}

bool UShockActionDisableOrEnableResurrectionStation::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World) > 0;
}
