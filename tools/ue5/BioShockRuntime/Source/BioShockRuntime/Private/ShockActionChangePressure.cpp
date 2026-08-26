#include "ShockActionChangePressure.h"

UShockActionChangePressure::UShockActionChangePressure()
{
	ActionClassName = TEXT("ActionChangePressure");
}

void UShockActionChangePressure::Configure(FName InRegion, uint8 InPressure)
{
	RegionName = InRegion;
	DesiredPressure = InPressure;
}

bool UShockActionChangePressure::RequestChange()
{
	if (RegionName.IsNone())
	{
		return false;
	}
	LastRegionName = RegionName;
	return true;
}
