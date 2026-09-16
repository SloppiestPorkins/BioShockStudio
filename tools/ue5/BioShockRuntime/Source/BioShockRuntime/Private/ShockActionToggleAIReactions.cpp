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
			AI->SetScriptedUseFullBodyHitReactions(
				FullBodyHitReactions == EShockToggleHitReactions::Use);
		}
		if (QuickHitReactions != EShockToggleHitReactions::DoNotChange)
		{
			AI->SetScriptedUseQuickHitReactions(
				QuickHitReactions == EShockToggleHitReactions::Use);
		}
		++Applied;
	}
	return Applied;
}

bool UShockActionToggleAIReactions::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World) > 0;
}
