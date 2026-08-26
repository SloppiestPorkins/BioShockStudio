#include "ShockActionDisablePlayerMovement.h"

UShockActionDisablePlayerMovement::UShockActionDisablePlayerMovement()
{
	ActionClassName = TEXT("ActionDisablePlayerMovement");
}

void UShockActionDisablePlayerMovement::Configure(bool bInDisable)
{
	bDisableMovement = bInDisable;
}

bool UShockActionDisablePlayerMovement::RequestSet()
{
	bLastDisableMovement = bDisableMovement;
	return true;
}
