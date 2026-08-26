#include "ShockActionStartAIHeadTracking.h"

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
