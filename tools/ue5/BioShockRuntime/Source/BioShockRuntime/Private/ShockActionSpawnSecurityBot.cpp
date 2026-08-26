#include "ShockActionSpawnSecurityBot.h"

UShockActionSpawnSecurityBot::UShockActionSpawnSecurityBot()
{
	ActionClassName = TEXT("ActionSpawnSecurityBot");
}

void UShockActionSpawnSecurityBot::Configure(FName InSpawner, bool bInGive, FName InPawn)
{
	SpawnerLabel = InSpawner;
	bImmediatelyGiveBotToPawn = bInGive;
	ReceivingPawnLabel = InPawn;
}

bool UShockActionSpawnSecurityBot::RequestSpawn()
{
	if (SpawnerLabel.IsNone())
	{
		return false;
	}
	LastSpawnerLabel = SpawnerLabel;
	return true;
}
