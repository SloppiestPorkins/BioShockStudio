#include "ShockActionTweakAIVision.h"

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
