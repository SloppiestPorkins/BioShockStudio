#include "ShockActionMuteAI.h"

#include "BaseShockAI.h"

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

int32 UShockActionMuteAI::ApplyInWorld(UWorld* World)
{
	if (!RequestMute())
	{
		return 0;
	}
	int32 Applied = 0;
	for (ABaseShockAI* AI : ABaseShockAI::CollectLabeled(World, AILabel))
	{
		AI->bMuted = bShouldMuteAI;
		++Applied;
	}
	return Applied;
}
