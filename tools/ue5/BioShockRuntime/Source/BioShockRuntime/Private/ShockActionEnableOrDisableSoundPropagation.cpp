#include "ShockActionEnableOrDisableSoundPropagation.h"

UShockActionEnableOrDisableSoundPropagation::UShockActionEnableOrDisableSoundPropagation()
{
	ActionClassName = TEXT("ActionEnableOrDisableSoundPropagation");
}
void UShockActionEnableOrDisableSoundPropagation::Configure(bool bInEnable)
{
	bEnable = bInEnable;
}
bool UShockActionEnableOrDisableSoundPropagation::RequestSet()
{
	return true;
}
