#include "ShockActionTellAIToWait.h"

#include "BaseShockAI.h"

UShockActionTellAIToWait::UShockActionTellAIToWait()
{
	ActionClassName = TEXT("ActionTellAIToWait");
}

void UShockActionTellAIToWait::Configure(FName InAILabel)
{
	AILabel = InAILabel;
}

bool UShockActionTellAIToWait::RequestWait()
{
	if (AILabel.IsNone())
	{
		return false;
	}
	LastAILabel = AILabel;
	return true;
}

int32 UShockActionTellAIToWait::ApplyInWorld(UWorld* World)
{
	if (!RequestWait())
	{
		return 0;
	}
	int32 Applied = 0;
	for (ABaseShockAI* AI : ABaseShockAI::CollectLabeled(World, AILabel))
	{
		AI->bToldToWait = true;
		++Applied;
	}
	return Applied;
}
