#include "ShockActionEnableOrDisableHudMessages.h"

UShockActionEnableOrDisableHudMessages::UShockActionEnableOrDisableHudMessages()
{
	ActionClassName = TEXT("ActionEnableOrDisableHudMessages");
}

void UShockActionEnableOrDisableHudMessages::Configure(bool bInDisable)
{
	bDisableHudMessages = bInDisable;
}

bool UShockActionEnableOrDisableHudMessages::RequestSet()
{
	bLastDisableHudMessages = bDisableHudMessages;
	return true;
}
