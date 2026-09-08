#include "ShockActionManipulateSpawnZoneRepopulation.h"

#include "EngineUtils.h"
#include "ShockEnemySpawner.h"
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
	int32 Applied = 1;
	if (AggressorState != EShockSpawnZoneRepopulationState::NoChange)
	{
		const bool bEnable = AggressorState == EShockSpawnZoneRepopulationState::Enable;
		for (TActorIterator<AShockAggressorSpawner> It(World); It; ++It)
		{
			if (*It && (*It)->HasZone(SpawnZoneName))
			{
				(*It)->SetRepopulationEnabled(bEnable, bEnable);
				++Applied;
			}
		}
	}
	return Applied;
}

bool UShockActionManipulateSpawnZoneRepopulation::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World) > 0;
}
