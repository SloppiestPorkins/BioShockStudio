#include "ShockActionStopHUD.h"

UShockActionStopHUD::UShockActionStopHUD()
{
	ActionClassName = TEXT("ActionStopHUD");
}

bool UShockActionStopHUD::RequestStop()
{
	bStopRequested = true;
	return true;
}
