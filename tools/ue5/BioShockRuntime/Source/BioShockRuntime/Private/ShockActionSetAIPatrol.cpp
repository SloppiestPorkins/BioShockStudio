#include "ShockActionSetAIPatrol.h"

#include "BaseShockAI.h"

UShockActionSetAIPatrol::UShockActionSetAIPatrol()
{
	ActionClassName = TEXT("ActionSetAIPatrol");
}

void UShockActionSetAIPatrol::Configure(FName InAggressor, FName InPatrol)
{
	AggressorLabel = InAggressor;
	PatrolName = InPatrol;
}

bool UShockActionSetAIPatrol::RequestSetPatrol()
{
	if (AggressorLabel.IsNone() || PatrolName.IsNone())
	{
		return false;
	}
	LastAggressorLabel = AggressorLabel;
	LastPatrolName = PatrolName;
	return true;
}

int32 UShockActionSetAIPatrol::ApplyInWorld(UWorld* World)
{
	if (!RequestSetPatrol())
	{
		return 0;
	}
	int32 Applied = 0;
	for (ABaseShockAI* AI : ABaseShockAI::CollectLabeled(World, AggressorLabel))
	{
		AI->PatrolName = PatrolName;
		++Applied;
	}
	return Applied;
}
