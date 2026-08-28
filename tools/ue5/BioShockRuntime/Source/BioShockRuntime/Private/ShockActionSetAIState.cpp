#include "ShockActionSetAIState.h"

#include "BaseShockAI.h"

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

int32 UShockActionSetAIState::ApplyInWorld(UWorld* World)
{
	if (!RequestSet())
	{
		return 0;
	}
	int32 Applied = 0;
	for (ABaseShockAI* AI : ABaseShockAI::CollectLabeled(World, AILabel))
	{
		AI->ScriptedAIState = AIState;
		++Applied;
	}
	return Applied;
}
