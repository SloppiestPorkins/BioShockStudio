#include "ShockActionManipulateSpawnZoneRepopulation.h"

UShockActionManipulateSpawnZoneRepopulation::UShockActionManipulateSpawnZoneRepopulation()
{
	ActionClassName = TEXT("ActionManipulateSpawnZoneRepopulation");
}

void UShockActionManipulateSpawnZoneRepopulation::Configure(
	FName InZone,
	EShockSpawnZoneRepopulationState InAggressor,
	EShockSpawnZoneRepopulationState InProtector)
{
	SpawnZoneName = InZone;
	AggressorState = InAggressor;
	ProtectorState = InProtector;
}

bool UShockActionManipulateSpawnZoneRepopulation::RequestManipulate()
{
	if (SpawnZoneName.IsNone())
	{
		return false;
	}
	LastSpawnZoneName = SpawnZoneName;
	return true;
}
