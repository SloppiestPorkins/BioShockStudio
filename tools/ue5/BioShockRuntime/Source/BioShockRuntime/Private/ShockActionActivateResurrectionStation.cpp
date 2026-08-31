#include "ShockActionActivateResurrectionStation.h"

#include "ShockPlayer.h"

UShockActionActivateResurrectionStation::UShockActionActivateResurrectionStation()
{
	ActionClassName = TEXT("ActionActivateResurrectionStation");
	bActivateStation = true;
}

void UShockActionActivateResurrectionStation::Configure(FName InStation, bool bInActivate)
{
	ResurrectionStationLabel = InStation;
	bActivateStation = bInActivate;
}

bool UShockActionActivateResurrectionStation::RequestActivate()
{
	if (ResurrectionStationLabel.IsNone())
	{
		return false;
	}
	LastStationLabel = ResurrectionStationLabel;
	return true;
}

int32 UShockActionActivateResurrectionStation::ApplyInWorld(UWorld* World)
{
	if (!RequestActivate() || !World)
	{
		return 0;
	}
	AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World);
	if (!Player)
	{
		return 0;
	}
	Player->SetResurrectionStationActivated(ResurrectionStationLabel, bActivateStation);
	return 1;
}

bool UShockActionActivateResurrectionStation::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World) > 0;
}
