#include "ShockActionPlaceItemInContainer.h"

UShockActionPlaceItemInContainer::UShockActionPlaceItemInContainer()
{
	ActionClassName = TEXT("ActionPlaceItemInContainer");
}

void UShockActionPlaceItemInContainer::Configure(FName InContainer)
{
	ContainerLabel = InContainer;
}

bool UShockActionPlaceItemInContainer::RequestPlace()
{
	if (ContainerLabel.IsNone())
	{
		return false;
	}
	LastContainerLabel = ContainerLabel;
	return true;
}
