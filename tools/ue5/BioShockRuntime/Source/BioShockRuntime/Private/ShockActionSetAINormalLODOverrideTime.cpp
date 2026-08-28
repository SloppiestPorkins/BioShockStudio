#include "ShockActionSetAINormalLODOverrideTime.h"

#include "BaseShockAI.h"

UShockActionSetAINormalLODOverrideTime::UShockActionSetAINormalLODOverrideTime()
{
	ActionClassName = TEXT("ActionSetAINormalLODOverrideTime");
}

void UShockActionSetAINormalLODOverrideTime::Configure(FName InAILabel, float InTime)
{
	AILabel = InAILabel;
	LODOverrideTime = InTime;
}

bool UShockActionSetAINormalLODOverrideTime::RequestSet()
{
	if (AILabel.IsNone())
	{
		return false;
	}
	LastAILabel = AILabel;
	return true;
}

int32 UShockActionSetAINormalLODOverrideTime::ApplyInWorld(UWorld* World)
{
	if (!RequestSet())
	{
		return 0;
	}
	int32 Applied = 0;
	for (ABaseShockAI* AI : ABaseShockAI::CollectLabeled(World, AILabel))
	{
		AI->LODOverrideTime = LODOverrideTime;
		++Applied;
	}
	return Applied;
}
