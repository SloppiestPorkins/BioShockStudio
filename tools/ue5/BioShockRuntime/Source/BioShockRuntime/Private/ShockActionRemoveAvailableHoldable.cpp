#include "ShockActionRemoveAvailableHoldable.h"

#include "ShockPlayer.h"

UShockActionRemoveAvailableHoldable::UShockActionRemoveAvailableHoldable()
{
	ActionClassName = TEXT("ActionRemoveAvailableHoldable");
}

void UShockActionRemoveAvailableHoldable::Configure(FName InHoldable)
{
	HoldableClass = InHoldable;
}

bool UShockActionRemoveAvailableHoldable::RequestRemove()
{
	if (HoldableClass.IsNone())
	{
		return false;
	}
	LastHoldableClass = HoldableClass;
	return true;
}

int32 UShockActionRemoveAvailableHoldable::ApplyInWorld(UWorld* World)
{
	if (!RequestRemove() || !World)
	{
		return 0;
	}
	AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World);
	if (!Player)
	{
		return 0;
	}
	Player->RemoveAvailableHoldable(HoldableClass);
	return 1;
}
