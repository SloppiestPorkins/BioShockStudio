#include "ShockActionForcePlayerMove.h"

UShockActionForcePlayerMove::UShockActionForcePlayerMove()
{
	ActionClassName = TEXT("ActionForcePlayerMove");
}

void UShockActionForcePlayerMove::Configure(
	FName InMarker,
	FName InBone,
	float InTimeOut,
	float InLocDelta,
	float InRotDelta)
{
	MarkerLabel = InMarker;
	MarkerBoneName = InBone;
	TimeOut = InTimeOut;
	LocationDeltaPerSecond = InLocDelta;
	RotationDeltaPerSecond = InRotDelta;
}

bool UShockActionForcePlayerMove::RequestMove()
{
	if (MarkerLabel.IsNone())
	{
		return false;
	}
	LastMarkerLabel = MarkerLabel;
	return true;
}
