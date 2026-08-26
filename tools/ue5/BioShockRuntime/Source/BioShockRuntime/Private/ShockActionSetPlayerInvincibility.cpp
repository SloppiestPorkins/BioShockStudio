#include "ShockActionSetPlayerInvincibility.h"

UShockActionSetPlayerInvincibility::UShockActionSetPlayerInvincibility()
{
	ActionClassName = TEXT("ActionSetPlayerInvincibility");
	bInvincible = true;
}

void UShockActionSetPlayerInvincibility::Configure(bool bInInvincible)
{
	bInvincible = bInInvincible;
}

bool UShockActionSetPlayerInvincibility::RequestSet()
{
	bLastInvincible = bInvincible;
	return true;
}
