#include "ShockActionSpawnLinkedGathererAndProtector.h"

UShockActionSpawnLinkedGathererAndProtector::UShockActionSpawnLinkedGathererAndProtector()
{
	ActionClassName = TEXT("ActionSpawnLinkedGathererAndProtector");
	bProtectorCorpseCanBeRemoved = true;
	bGathererCorpseCanBeRemoved = true;
	GathererVulnerableState = 1;
}

void UShockActionSpawnLinkedGathererAndProtector::Configure(
	FName InProtectorType,
	FName InVent,
	FName InProtector,
	FName InGatherer,
	bool bInForce)
{
	ProtectorTypeToSpawn = InProtectorType;
	AssociatedGathererVentLabel = InVent;
	ProtectorLabel = InProtector;
	GathererLabel = InGatherer;
	bForceSpawn = bInForce;
}

bool UShockActionSpawnLinkedGathererAndProtector::RequestSpawn()
{
	if (GathererLabel.IsNone() && ProtectorLabel.IsNone())
	{
		return false;
	}
	LastGathererLabel = GathererLabel;
	return true;
}
