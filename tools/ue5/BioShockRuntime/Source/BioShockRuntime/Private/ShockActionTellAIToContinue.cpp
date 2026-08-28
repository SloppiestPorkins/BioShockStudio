#include "ShockActionTellAIToContinue.h"

#include "BaseShockAI.h"

UShockActionTellAIToContinue::UShockActionTellAIToContinue()
{
	ActionClassName = TEXT("ActionTellAIToContinue");
}

void UShockActionTellAIToContinue::Configure(FName InAILabel)
{
	AILabel = InAILabel;
}

bool UShockActionTellAIToContinue::RequestContinue()
{
	if (AILabel.IsNone())
	{
		return false;
	}
	LastAILabel = AILabel;
	return true;
}

int32 UShockActionTellAIToContinue::ApplyInWorld(UWorld* World)
{
	if (!RequestContinue())
	{
		return 0;
	}
	int32 Applied = 0;
	for (ABaseShockAI* AI : ABaseShockAI::CollectLabeled(World, AILabel))
	{
		AI->bToldToWait = false;
		++Applied;
	}
	return Applied;
}
