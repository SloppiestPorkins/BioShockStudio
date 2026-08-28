#include "ShockActionGiveItemsToPlayer.h"

#include "ShockPlayer.h"

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

int32 UShockActionGiveItemsToPlayer::ApplyInWorld(UWorld* World)
{
	LastAppliedCount = 0;
	if (!RequestGive() || !World)
	{
		return 0;
	}
	AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World);
	if (!Player)
	{
		return 0;
	}
	if (Player->AddStackToInventory(ItemClass, StackSize) <= 0)
	{
		return 0;
	}
	LastAppliedCount = 1;
	return 1;
}
