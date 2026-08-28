#include "ShockActionRemoveItemsFromPlayer.h"

#include "ShockPlayer.h"

UShockActionRemoveItemsFromPlayer::UShockActionRemoveItemsFromPlayer()
{
	ActionClassName = TEXT("ActionRemoveItemsFromPlayer");
}

bool UShockActionRemoveItemsFromPlayer::RequestRemove()
{
	if (ItemClass.IsNone() || StackSize <= 0)
	{
		return false;
	}
	LastRemovedItemClass = ItemClass;
	LastRemovedStackSize = StackSize;
	return true;
}

int32 UShockActionRemoveItemsFromPlayer::ApplyInWorld(UWorld* World)
{
	LastAppliedCount = 0;
	if (!RequestRemove() || !World)
	{
		return 0;
	}
	AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World);
	if (!Player)
	{
		return 0;
	}
	Player->RemoveStackFromInventory(ItemClass, StackSize);
	LastAppliedCount = 1;
	return 1;
}
