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
