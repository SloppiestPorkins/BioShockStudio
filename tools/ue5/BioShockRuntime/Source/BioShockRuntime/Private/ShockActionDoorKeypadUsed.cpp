#include "ShockActionDoorKeypadUsed.h"

UShockActionDoorKeypadUsed::UShockActionDoorKeypadUsed()
{
	ActionClassName = TEXT("ActionDoorKeypadUsed");
}

void UShockActionDoorKeypadUsed::Configure(FName InKeypad, bool bInSuccess)
{
	DoorKeypadControlLabel = InKeypad;
	bSuccess = bInSuccess;
}

bool UShockActionDoorKeypadUsed::RequestUsed()
{
	if (DoorKeypadControlLabel.IsNone())
	{
		return false;
	}
	LastDoorKeypadControlLabel = DoorKeypadControlLabel;
	return true;
}

bool UShockActionDoorKeypadUsed::ApplyInWorld(const FShockActionContext& Ctx)
{
	(void)Ctx;
	// SCR-B17: no DoorKeypad / keypad-control actor class exists in BioShockRuntime yet, so
	// Success cannot be delivered to a control. Record the request only.
	return RequestUsed();
}
