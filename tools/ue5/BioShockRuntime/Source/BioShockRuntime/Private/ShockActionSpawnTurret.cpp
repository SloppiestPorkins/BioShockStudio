#include "ShockActionSpawnTurret.h"

UShockActionSpawnTurret::UShockActionSpawnTurret()
{
	ActionClassName = TEXT("ActionSpawnTurret");
}

void UShockActionSpawnTurret::Configure(FName InSpawner)
{
	SpawnerLabel = InSpawner;
}

bool UShockActionSpawnTurret::RequestSpawn()
{
	if (SpawnerLabel.IsNone())
	{
		return false;
	}
	LastSpawnerLabel = SpawnerLabel;
	return true;
}
