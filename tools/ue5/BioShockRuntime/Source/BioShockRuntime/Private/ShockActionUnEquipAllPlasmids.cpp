#include "ShockActionUnEquipAllPlasmids.h"

UShockActionUnEquipAllPlasmids::UShockActionUnEquipAllPlasmids()
{
	ActionClassName = TEXT("ActionUnEquipAllPlasmids");
}

bool UShockActionUnEquipAllPlasmids::RequestUnequip()
{
	bUnequipRequested = true;
	return true;
}
