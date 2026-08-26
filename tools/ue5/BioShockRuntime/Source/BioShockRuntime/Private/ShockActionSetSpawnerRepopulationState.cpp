#include "ShockActionSetSpawnerRepopulationState.h"

UShockActionSetSpawnerRepopulationState::UShockActionSetSpawnerRepopulationState()
{
	ActionClassName = TEXT("ActionSetSpawnerRepopulationState");
}

void UShockActionSetSpawnerRepopulationState::Configure(FName InSpawner, bool bInFlag)
{
	SpawnerLabel = InSpawner;
	bFlag = bInFlag;
}

bool UShockActionSetSpawnerRepopulationState::RequestSet()
{
	if (SpawnerLabel.IsNone())
	{
		return false;
	}
	LastSpawnerLabel = SpawnerLabel;
	return true;
}
