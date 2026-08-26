#include "ShockActionSetGathererVentPlayerCanSpawn.h"

UShockActionSetGathererVentPlayerCanSpawn::UShockActionSetGathererVentPlayerCanSpawn()
{
	ActionClassName = TEXT("ActionSetGathererVentPlayerCanSpawn");
}

void UShockActionSetGathererVentPlayerCanSpawn::Configure(FName InVent, bool bInFlag)
{
	GathererVentLabel = InVent;
	bFlag = bInFlag;
}

bool UShockActionSetGathererVentPlayerCanSpawn::RequestSet()
{
	if (GathererVentLabel.IsNone())
	{
		return false;
	}
	LastGathererVentLabel = GathererVentLabel;
	return true;
}
