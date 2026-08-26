#include "ShockActionSetNextAssassinTeleportPoint.h"

UShockActionSetNextAssassinTeleportPoint::UShockActionSetNextAssassinTeleportPoint()
{
	ActionClassName = TEXT("ActionSetNextAssassinTeleportPoint");
}

void UShockActionSetNextAssassinTeleportPoint::Configure(FName InAssassin, FName InTeleport)
{
	AssassinLabel = InAssassin;
	TeleportLabel = InTeleport;
}

bool UShockActionSetNextAssassinTeleportPoint::RequestSet()
{
	if (AssassinLabel.IsNone() || TeleportLabel.IsNone())
	{
		return false;
	}
	LastAssassinLabel = AssassinLabel;
	return true;
}
