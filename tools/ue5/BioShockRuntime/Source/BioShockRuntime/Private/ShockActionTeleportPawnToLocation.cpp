#include "ShockActionTeleportPawnToLocation.h"

UShockActionTeleportPawnToLocation::UShockActionTeleportPawnToLocation()
{
	ActionClassName = TEXT("ActionTeleportPawnToLocation");
}

void UShockActionTeleportPawnToLocation::Configure(FName InPawnLabel, FName InMarkerLabel)
{
	PawnLabel = InPawnLabel;
	MarkerLabel = InMarkerLabel;
}

bool UShockActionTeleportPawnToLocation::RequestTeleport()
{
	if (PawnLabel.IsNone() || MarkerLabel.IsNone())
	{
		return false;
	}
	LastPawnLabel = PawnLabel;
	LastMarkerLabel = MarkerLabel;
	return true;
}
