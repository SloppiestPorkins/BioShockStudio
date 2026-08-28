#include "ShockActionToggleAIReactions.h"

#include "BaseShockAI.h"

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

int32 UShockActionToggleAIReactions::ApplyInWorld(UWorld* World)
{
	if (!RequestToggle())
	{
		return 0;
	}
	int32 Applied = 0;
	for (ABaseShockAI* AI : ABaseShockAI::CollectLabeled(World, AILabel))
	{
		if (FullBodyHitReactions != EShockToggleHitReactions::DoNotChange)
		{
			AI->FullBodyHitReactions = static_cast<uint8>(FullBodyHitReactions);
		}
		if (QuickHitReactions != EShockToggleHitReactions::DoNotChange)
		{
			AI->QuickHitReactions = static_cast<uint8>(QuickHitReactions);
		}
		++Applied;
	}
	return Applied;
}
