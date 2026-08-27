#include "ShockActionForcePlayerCrouch.h"

UShockActionForcePlayerCrouch::UShockActionForcePlayerCrouch()
{
	ActionClassName = TEXT("ActionForcePlayerCrouch");
}

void UShockActionForcePlayerCrouch::Configure(bool bInShouldCrouch)
{
	bShouldCrouch = bInShouldCrouch;
}

bool UShockActionForcePlayerCrouch::RequestCrouch()
{
	bLastShouldCrouch = bShouldCrouch;
	return true;
}
