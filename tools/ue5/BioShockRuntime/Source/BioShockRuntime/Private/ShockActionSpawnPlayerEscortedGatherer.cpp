#include "ShockActionSpawnPlayerEscortedGatherer.h"

UShockActionSpawnPlayerEscortedGatherer::UShockActionSpawnPlayerEscortedGatherer()
{
	ActionClassName = TEXT("ActionSpawnPlayerEscortedGatherer");
	SpawnedGathererLabel = TEXT("PlayerEscortedGatherer");
	bCorpseCanBeRemoved = true;
	GathererVulnerableState = 1;
}

void UShockActionSpawnPlayerEscortedGatherer::Configure(
	FName InVent,
	FName InPos,
	FName InSpawned,
	bool bInForce,
	bool bInEscort)
{
	GathererVentLabel = InVent;
	SpawnPositionLabel = InPos;
	SpawnedGathererLabel = InSpawned;
	bForceSpawn = bInForce;
	bShouldPlayerEscort = bInEscort;
}

bool UShockActionSpawnPlayerEscortedGatherer::RequestSpawn()
{
	if (GathererVentLabel.IsNone() || SpawnedGathererLabel.IsNone())
	{
		return false;
	}
	LastSpawnedGathererLabel = SpawnedGathererLabel;
	return true;
}
