#include "ShockActionStopAIHeadTracking.h"

UShockActionStopAIHeadTracking::UShockActionStopAIHeadTracking()
{
	ActionClassName = TEXT("ActionStopAIHeadTracking");
}

void UShockActionStopAIHeadTracking::Configure(FName InAILabel)
{
	AILabel = InAILabel;
}

bool UShockActionStopAIHeadTracking::RequestStop()
{
	if (AILabel.IsNone())
	{
		return false;
	}
	LastAILabel = AILabel;
	return true;
}
