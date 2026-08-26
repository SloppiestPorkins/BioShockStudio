#include "ShockActionSpawnAI.h"

UShockActionSpawnAI::UShockActionSpawnAI()
{
	ActionClassName = TEXT("ActionSpawnAI");
	bCorpseCanBeRemoved = true;
}

void UShockActionSpawnAI::Configure(
	FName InAIType,
	FName InSpawnLocationLabel,
	FName InSpawnedAILabel,
	float InMinRadius,
	float InMaxRadius,
	bool bInForceSpawn)
{
	AITypeToSpawn = InAIType;
	SpawnLocationLabel = InSpawnLocationLabel;
	SpawnedAILabel = InSpawnedAILabel;
	MinRadiusToSpawnAroundSpawnLoc = InMinRadius;
	MaxRadiusToSpawnAroundSpawnLoc = InMaxRadius;
	bForceSpawn = bInForceSpawn;
}

bool UShockActionSpawnAI::RequestSpawn()
{
	if (AITypeToSpawn.IsNone())
	{
		return false;
	}
	LastRequestedAIType = AITypeToSpawn;
	LastRequestedLocationLabel = SpawnLocationLabel;
	return true;
}
