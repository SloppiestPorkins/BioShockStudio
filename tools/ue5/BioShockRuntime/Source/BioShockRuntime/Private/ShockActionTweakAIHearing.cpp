#include "ShockActionTweakAIHearing.h"

#include "BaseShockAI.h"

UShockActionTweakAIHearing::UShockActionTweakAIHearing()
{
	ActionClassName = TEXT("ActionTweakAIHearing");
	AIClass = FName(TEXT("ShockAI"));
}

void UShockActionTweakAIHearing::Configure(FName InAILabel, bool bInTurnHearingOn)
{
	AILabel = InAILabel;
	bTurnHearingOn = bInTurnHearingOn;
}

bool UShockActionTweakAIHearing::RequestTweak()
{
	if (AILabel.IsNone())
	{
		return false;
	}
	LastTweakedAILabel = AILabel;
	bLastTurnHearingOn = bTurnHearingOn;
	return true;
}

int32 UShockActionTweakAIHearing::ApplyInWorld(UWorld* World)
{
	if (!RequestTweak())
	{
		return 0;
	}
	int32 Applied = 0;
	for (ABaseShockAI* AI : ABaseShockAI::CollectLabeled(World, AILabel))
	{
		AI->bHearingOn = bTurnHearingOn;
		++Applied;
	}
	return Applied;
}
