#include "ShockActionGiveItemsToPlayer.h"

#include "EngineUtils.h"
#include "GameFramework/PlayerController.h"
#include "ShockPlayer.h"

namespace
{
	AShockPlayer* FindLocalShockPlayer(UWorld* World)
	{
		if (!World)
		{
			return nullptr;
		}
		if (APlayerController* PC = World->GetFirstPlayerController())
		{
			if (AShockPlayer* Possessed = Cast<AShockPlayer>(PC->GetPawn()))
			{
				return Possessed;
			}
		}
		for (TActorIterator<AShockPlayer> It(World); It; ++It)
		{
			if (*It)
			{
				return *It;
			}
		}
		return nullptr;
	}
}

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
	AShockPlayer* Player = FindLocalShockPlayer(World);
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
