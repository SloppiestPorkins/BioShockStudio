#include "ShockActionMuteAI.h"

UShockActionMuteAI::UShockActionMuteAI()
{
	ActionClassName = TEXT("ActionMuteAI");
}

void UShockActionMuteAI::Configure(FName InAILabel, bool bInShouldMuteAI)
{
	AILabel = InAILabel;
	bShouldMuteAI = bInShouldMuteAI;
}

bool UShockActionMuteAI::RequestMute()
{
	if (AILabel.IsNone())
	{
		return false;
	}
	LastMutedAILabel = AILabel;
	bLastMuted = bShouldMuteAI;
	return true;
}
