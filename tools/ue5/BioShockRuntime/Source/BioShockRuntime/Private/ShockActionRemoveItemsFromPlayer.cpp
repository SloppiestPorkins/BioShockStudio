#include "ShockActionRemoveItemsFromPlayer.h"

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
