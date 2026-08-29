#include "ShockActionStartAIHeadTracking.h"

#include "BaseShockAI.h"

UShockActionStartAIHeadTracking::UShockActionStartAIHeadTracking()
{
	ActionClassName = TEXT("ActionStartAIHeadTracking");
}

void UShockActionStartAIHeadTracking::Configure(
	FName InAILabel,
	FName InTarget,
	bool bInQuickLook,
	float InDuration,
	FVector InOffset)
{
	AILabel = InAILabel;
	HeadTrackTargetLabel = InTarget;
	bIsQuickLook = bInQuickLook;
	Duration = InDuration;
	Offset = InOffset;
}

bool UShockActionStartAIHeadTracking::RequestStart()
{
	if (AILabel.IsNone())
	{
		return false;
	}
	LastAILabel = AILabel;
	return true;
}

int32 UShockActionStartAIHeadTracking::ApplyInWorld(UWorld* World)
{
	if (!RequestStart())
	{
		return 0;
	}
	int32 Applied = 0;
	for (ABaseShockAI* AI : ABaseShockAI::CollectLabeled(World, AILabel))
	{
		AI->BeginHeadTracking(HeadTrackTargetLabel, bIsQuickLook, Duration, Offset);
		++Applied;
	}
	return Applied;
}
