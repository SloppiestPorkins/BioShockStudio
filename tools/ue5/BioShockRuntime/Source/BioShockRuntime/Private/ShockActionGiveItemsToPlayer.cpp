#include "ShockActionGiveItemsToPlayer.h"

UShockActionGiveItemsToPlayer::UShockActionGiveItemsToPlayer()
{
	ActionClassName = TEXT("ActionGiveItemsToPlayer");
}

bool UShockActionGiveItemsToPlayer::RequestGive()
{
	if (ItemClass.IsNone() || StackSize <= 0)
	{
		return false;
	}
	LastGrantedItemClass = ItemClass;
	LastGrantedStackSize = StackSize;
	return true;
}
