#include "ShockActionResetProtectorAttackTargets.h"

UShockActionResetProtectorAttackTargets::UShockActionResetProtectorAttackTargets()
{
	ActionClassName = TEXT("ActionResetProtectorAttackTargets");
}

void UShockActionResetProtectorAttackTargets::Configure(FName InProtector)
{
	ProtectorLabel = InProtector;
}

bool UShockActionResetProtectorAttackTargets::RequestReset()
{
	if (ProtectorLabel.IsNone())
	{
		return false;
	}
	LastProtectorLabel = ProtectorLabel;
	return true;
}
