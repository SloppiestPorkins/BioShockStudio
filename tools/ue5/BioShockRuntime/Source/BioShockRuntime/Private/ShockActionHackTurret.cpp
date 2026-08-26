#include "ShockActionHackTurret.h"

UShockActionHackTurret::UShockActionHackTurret()
{
	ActionClassName = TEXT("ActionHackTurret");
}

void UShockActionHackTurret::Configure(FName InTurret, bool bInHacked)
{
	TurretLabel = InTurret;
	bSetHacked = bInHacked;
}

bool UShockActionHackTurret::RequestHack()
{
	if (TurretLabel.IsNone())
	{
		return false;
	}
	LastTurretLabel = TurretLabel;
	return true;
}
