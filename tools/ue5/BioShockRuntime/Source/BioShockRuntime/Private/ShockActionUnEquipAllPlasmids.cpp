#include "ShockActionUnEquipAllPlasmids.h"

#include "ShockPlayer.h"

UShockActionUnEquipAllPlasmids::UShockActionUnEquipAllPlasmids()
{
	ActionClassName = TEXT("ActionUnEquipAllPlasmids");
}

bool UShockActionUnEquipAllPlasmids::RequestUnequip()
{
	bUnequipRequested = true;
	return true;
}

bool UShockActionUnEquipAllPlasmids::ApplyInWorld(UWorld* World)
{
	if (!World)
	{
		return false;
	}

	AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World);
	if (!Player)
	{
		return false;
	}

	Player->ClearAllPlasmids();
	bUnequipRequested = true;
	return true;
}

bool UShockActionUnEquipAllPlasmids::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World);
}
