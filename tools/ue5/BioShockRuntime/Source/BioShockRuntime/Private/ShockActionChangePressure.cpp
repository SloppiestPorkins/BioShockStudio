#include "ShockActionChangePressure.h"

#include "ShockPlayer.h"

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

int32 UShockActionChangePressure::ApplyInWorld(UWorld* World)
{
	if (!RequestChange())
	{
		return 0;
	}
	AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World);
	if (!Player)
	{
		return 0;
	}
	Player->SetRegionPressure(RegionName, DesiredPressure);
	return 1;
}
