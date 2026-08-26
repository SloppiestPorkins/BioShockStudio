#include "ShockActionToggleAIReactions.h"

UShockActionToggleAIReactions::UShockActionToggleAIReactions()
{
	ActionClassName = TEXT("ActionToggleAIReactions");
}

void UShockActionToggleAIReactions::Configure(
	FName InAILabel,
	EShockToggleHitReactions InFullBody,
	EShockToggleHitReactions InQuick)
{
	AILabel = InAILabel;
	FullBodyHitReactions = InFullBody;
	QuickHitReactions = InQuick;
}

bool UShockActionToggleAIReactions::RequestToggle()
{
	if (AILabel.IsNone())
	{
		return false;
	}
	LastAILabel = AILabel;
	return true;
}
