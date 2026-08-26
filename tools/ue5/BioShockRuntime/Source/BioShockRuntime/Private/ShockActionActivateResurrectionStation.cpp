#include "ShockActionActivateResurrectionStation.h"

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
