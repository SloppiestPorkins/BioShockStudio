#include "ShockActionRemoveAvailableHoldable.h"

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
