#include "ShockActionEnableOrDisableLevelSwitching.h"

UShockActionEnableOrDisableLevelSwitching::UShockActionEnableOrDisableLevelSwitching()
{
	ActionClassName = TEXT("ActionEnableOrDisableLevelSwitching");
}

void UShockActionEnableOrDisableLevelSwitching::Configure(bool bInDisable)
{
	bDisableLevelSwitching = bInDisable;
}

bool UShockActionEnableOrDisableLevelSwitching::RequestSet()
{
	bLastDisableLevelSwitching = bDisableLevelSwitching;
	return true;
}
