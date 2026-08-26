#include "ShockActionSetHUDDisplayState.h"

UShockActionSetHUDDisplayState::UShockActionSetHUDDisplayState()
{
	ActionClassName = TEXT("ActionSetHUDDisplayState");
}

void UShockActionSetHUDDisplayState::Configure(bool bInEnable)
{
	bEnableHUD = bInEnable;
}

bool UShockActionSetHUDDisplayState::RequestSet()
{
	bLastEnableHUD = bEnableHUD;
	return true;
}
