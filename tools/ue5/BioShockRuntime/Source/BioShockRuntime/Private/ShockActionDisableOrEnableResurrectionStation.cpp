#include "ShockActionDisableOrEnableResurrectionStation.h"

#include "ShockPlayer.h"
#include "ShockVitaChamber.h"
#include "EngineUtils.h"

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
	int32 Applied = 0;
	for (TActorIterator<AShockVitaChamber> It(World); It; ++It)
	{
		if (It->ScriptLabel == StationLabel
			|| It->GetActorLabel().Equals(StationLabel.ToString(), ESearchCase::CaseSensitive))
		{
			It->SetAvailable(bEnable);
			++Applied;
		}
	}
	if (AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World))
	{
		Player->SetResurrectionStationEnabled(StationLabel, bEnable);
		Applied = FMath::Max(Applied, 1);
	}
	return Applied;
}

bool UShockActionDisableOrEnableResurrectionStation::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World) > 0;
}
