#include "ShockActionSetSpawnerRepopulationState.h"

#include "EngineUtils.h"
#include "ShockEnemySpawner.h"

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

bool UShockActionSetSpawnerRepopulationState::ApplyInWorld(const FShockActionContext& Ctx)
{
	if (!RequestSet() || !Ctx.World)
	{
		return false;
	}
	bool bApplied = false;
	for (TActorIterator<AShockAggressorSpawner> It(Ctx.World); It; ++It)
	{
		if (*It && (*It)->MatchesLabel(SpawnerLabel))
		{
			(*It)->SetRepopulationEnabled(bFlag, bFlag);
			bApplied = true;
		}
	}
	return bApplied;
}
