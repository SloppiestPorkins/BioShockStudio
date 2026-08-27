#include "ShockActionExitLoop.h"

UShockActionExitLoop::UShockActionExitLoop()
{
	ActionClassName = TEXT("ActionExitLoop");
}

bool UShockActionExitLoop::RequestExitLoop()
{
	bExitRequested = true;
	return true;
}
