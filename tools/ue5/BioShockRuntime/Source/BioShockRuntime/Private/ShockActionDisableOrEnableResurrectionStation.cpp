#include "ShockActionDisableOrEnableResurrectionStation.h"

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
