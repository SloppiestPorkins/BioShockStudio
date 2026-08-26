#include "ShockActionSetAIPatrol.h"

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
