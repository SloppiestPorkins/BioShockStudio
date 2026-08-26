#include "ShockActionGrenadierUseLiveGrenadeWeapon.h"

UShockActionGrenadierUseLiveGrenadeWeapon::UShockActionGrenadierUseLiveGrenadeWeapon()
{
	ActionClassName = TEXT("ActionGrenadierUseLiveGrenadeWeapon");
}

void UShockActionGrenadierUseLiveGrenadeWeapon::Configure(FName InGrenadier)
{
	GrenadierLabel = InGrenadier;
}

bool UShockActionGrenadierUseLiveGrenadeWeapon::RequestUse()
{
	if (GrenadierLabel.IsNone())
	{
		return false;
	}
	LastGrenadierLabel = GrenadierLabel;
	return true;
}
