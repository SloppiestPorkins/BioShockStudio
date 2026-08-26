#include "ShockActionSetAIState.h"

UShockActionSetAIState::UShockActionSetAIState()
{
	ActionClassName = TEXT("ActionSetAIState");
	AIState = 2;
}

void UShockActionSetAIState::Configure(FName InAILabel, int32 InState)
{
	AILabel = InAILabel;
	AIState = InState;
}

bool UShockActionSetAIState::RequestSet()
{
	if (AILabel.IsNone())
	{
		return false;
	}
	LastAILabel = AILabel;
	return true;
}
