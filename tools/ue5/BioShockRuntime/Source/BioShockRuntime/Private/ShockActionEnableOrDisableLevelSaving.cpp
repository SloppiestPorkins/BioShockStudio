#include "ShockActionEnableOrDisableLevelSaving.h"

UShockActionEnableOrDisableLevelSaving::UShockActionEnableOrDisableLevelSaving()
{
	ActionClassName = TEXT("ActionEnableOrDisableLevelSaving");
}

void UShockActionEnableOrDisableLevelSaving::Configure(bool bInDisable)
{
	bDisableLevelSaving = bInDisable;
}

bool UShockActionEnableOrDisableLevelSaving::RequestSet()
{
	bLastDisableLevelSaving = bDisableLevelSaving;
	return true;
}
