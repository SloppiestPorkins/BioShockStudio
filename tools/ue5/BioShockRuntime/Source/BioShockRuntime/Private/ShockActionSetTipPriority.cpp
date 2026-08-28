#include "ShockActionSetTipPriority.h"

#include "ShockPlayer.h"

UShockActionSetTipPriority::UShockActionSetTipPriority()
{
	ActionClassName = TEXT("ActionSetTipPriority");
}

void UShockActionSetTipPriority::Configure(FName InTipName, int32 InPriority)
{
	TipName = InTipName;
	Priority = InPriority;
}

bool UShockActionSetTipPriority::RequestSet()
{
	if (TipName.IsNone())
	{
		return false;
	}
	LastTipName = TipName;
	LastPriority = Priority;
	return true;
}

int32 UShockActionSetTipPriority::ApplyInWorld(UWorld* World)
{
	if (!RequestSet())
	{
		return 0;
	}
	AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World);
	if (!Player)
	{
		return 0;
	}
	Player->SetTipPriority(TipName, Priority);
	return 1;
}
