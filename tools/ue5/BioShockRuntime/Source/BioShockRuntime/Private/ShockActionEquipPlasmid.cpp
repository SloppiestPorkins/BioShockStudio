#include "ShockActionEquipPlasmid.h"

UShockActionEquipPlasmid::UShockActionEquipPlasmid()
{
	ActionClassName = TEXT("ActionEquipPlasmid");
}
void UShockActionEquipPlasmid::Configure(FName InPlasmid, int32 InSlot)
{
	Plasmid = InPlasmid;
	SlotNumber = InSlot;
}
bool UShockActionEquipPlasmid::RequestEquip()
{
	if (Plasmid.IsNone()) return false;
	return true;
}
