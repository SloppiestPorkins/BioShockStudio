#include "ShockActionForceGathererInteractable.h"

UShockActionForceGathererInteractable::UShockActionForceGathererInteractable()
{
	ActionClassName = TEXT("ActionForceGathererInteractable");
}

void UShockActionForceGathererInteractable::Configure(FName InGatherer, bool bInForceInteractable)
{
	GathererLabel = InGatherer;
	bForceInteractable = bInForceInteractable;
}

bool UShockActionForceGathererInteractable::RequestForce()
{
	if (GathererLabel.IsNone())
	{
		return false;
	}
	LastGathererLabel = GathererLabel;
	return true;
}
