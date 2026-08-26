#include "ShockActionClearAIDamageStates.h"

UShockActionClearAIDamageStates::UShockActionClearAIDamageStates()
{
	ActionClassName = TEXT("ActionClearAIDamageStates");
}

void UShockActionClearAIDamageStates::Configure(FName InAILabel)
{
	AILabel = InAILabel;
}

bool UShockActionClearAIDamageStates::RequestClear()
{
	if (AILabel.IsNone())
	{
		return false;
	}
	LastAILabel = AILabel;
	return true;
}
