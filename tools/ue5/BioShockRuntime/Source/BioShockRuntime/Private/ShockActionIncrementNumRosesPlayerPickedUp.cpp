#include "ShockActionIncrementNumRosesPlayerPickedUp.h"

UShockActionIncrementNumRosesPlayerPickedUp::UShockActionIncrementNumRosesPlayerPickedUp()
{
	ActionClassName = TEXT("ActionIncrementNumRosesPlayerPickedUp");
}

bool UShockActionIncrementNumRosesPlayerPickedUp::RequestIncrement()
{
	bRoseIncrementRequested = true;
	return true;
}
