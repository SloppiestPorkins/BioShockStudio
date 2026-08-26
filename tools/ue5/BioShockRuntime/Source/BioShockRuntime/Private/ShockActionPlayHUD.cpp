#include "ShockActionPlayHUD.h"

UShockActionPlayHUD::UShockActionPlayHUD()
{
	ActionClassName = TEXT("ActionPlayHUD");
}

bool UShockActionPlayHUD::RequestPlay()
{
	bPlayRequested = true;
	return true;
}
