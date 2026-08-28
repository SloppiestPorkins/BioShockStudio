#include "ShockActionManipulateSpawnZoneRepopulation.h"

#include "ShockPlayer.h"

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

int32 UShockActionManipulateSpawnZoneRepopulation::ApplyInWorld(UWorld* World)
{
	if (!RequestManipulate() || !World)
	{
		return 0;
	}
	AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World);
	if (!Player)
	{
		return 0;
	}
	Player->SetSpawnZoneRepopulation(
		SpawnZoneName,
		static_cast<uint8>(AggressorState),
		static_cast<uint8>(ProtectorState));
	return 1;
}
