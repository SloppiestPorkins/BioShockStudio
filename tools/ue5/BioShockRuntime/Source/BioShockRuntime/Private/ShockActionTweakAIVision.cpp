#include "ShockActionTweakAIVision.h"

#include "BaseShockAI.h"

UShockActionTweakAIVision::UShockActionTweakAIVision()
{
	ActionClassName = TEXT("ActionTweakAIVision");
	AIClass = FName(TEXT("ShockAI"));
}

void UShockActionTweakAIVision::Configure(
	FName InAILabel,
	bool bInTurnVisionOn,
	bool bInPlayerOnly,
	bool bInAlwaysSeePlayer)
{
	AILabel = InAILabel;
	bTurnVisionOn = bInTurnVisionOn;
	bAffectVisionOfPlayerOnly = bInPlayerOnly;
	bAlwaysSeePlayer = bInAlwaysSeePlayer;
}

bool UShockActionTweakAIVision::RequestTweak()
{
	if (AILabel.IsNone())
	{
		return false;
	}
	LastTweakedAILabel = AILabel;
	bLastTurnVisionOn = bTurnVisionOn;
	return true;
}

int32 UShockActionTweakAIVision::ApplyInWorld(UWorld* World)
{
	if (!RequestTweak())
	{
		return 0;
	}
	int32 Applied = 0;
	for (ABaseShockAI* AI : ABaseShockAI::CollectLabeled(World, AILabel))
	{
		AI->bVisionOn = bTurnVisionOn;
		AI->bAffectVisionOfPlayerOnly = bAffectVisionOfPlayerOnly;
		AI->bAlwaysSeePlayer = bAlwaysSeePlayer;
		++Applied;
	}
	return Applied;
}
