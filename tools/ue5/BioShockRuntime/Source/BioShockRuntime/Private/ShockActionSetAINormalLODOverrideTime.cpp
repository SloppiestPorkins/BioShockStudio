#include "ShockActionSetAINormalLODOverrideTime.h"

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
