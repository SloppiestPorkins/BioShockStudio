#include "ShockActionTweakAIHearing.h"

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
