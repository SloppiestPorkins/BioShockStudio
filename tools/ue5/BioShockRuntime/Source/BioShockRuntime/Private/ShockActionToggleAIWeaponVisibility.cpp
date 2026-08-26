#include "ShockActionToggleAIWeaponVisibility.h"

UShockActionToggleAIWeaponVisibility::UShockActionToggleAIWeaponVisibility()
{
	ActionClassName = TEXT("ActionToggleAIWeaponVisibility");
}

void UShockActionToggleAIWeaponVisibility::Configure(FName InAILabel, bool bInShow)
{
	AILabel = InAILabel;
	bShowWeapon = bInShow;
}

bool UShockActionToggleAIWeaponVisibility::RequestToggle()
{
	if (AILabel.IsNone())
	{
		return false;
	}
	LastAILabel = AILabel;
	return true;
}
