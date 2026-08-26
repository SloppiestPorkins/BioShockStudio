#include "ShockActionSetPawnInvincibility.h"

UShockActionSetPawnInvincibility::UShockActionSetPawnInvincibility()
{
	ActionClassName = TEXT("ActionSetPawnInvincibility");
	bInvincible = true;
}

void UShockActionSetPawnInvincibility::Configure(FName InPawn, bool bInInvincible)
{
	PawnLabel = InPawn;
	bInvincible = bInInvincible;
}

bool UShockActionSetPawnInvincibility::RequestSet()
{
	if (PawnLabel.IsNone())
	{
		return false;
	}
	LastPawnLabel = PawnLabel;
	return true;
}
