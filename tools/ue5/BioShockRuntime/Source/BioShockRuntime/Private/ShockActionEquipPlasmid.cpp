#include "ShockActionEquipPlasmid.h"

#include "ShockPlasmid.h"
#include "ShockPlayer.h"

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

bool UShockActionEquipPlasmid::ApplyInWorld(UWorld* World)
{
	if (!RequestEquip() || !World)
	{
		return false;
	}

	const TSubclassOf<UShockPlasmid> PlasmidClass = UShockPlasmid::ResolvePlasmidClass(Plasmid);
	if (!PlasmidClass)
	{
		return false;
	}

	AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World);
	if (!Player)
	{
		return false;
	}

	const int32 Slot = FMath::Max(0, SlotNumber);
	return Player->EquipPlasmid(PlasmidClass, Slot);
}

bool UShockActionEquipPlasmid::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World);
}
