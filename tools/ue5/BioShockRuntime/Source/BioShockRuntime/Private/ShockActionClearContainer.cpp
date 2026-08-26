#include "ShockActionClearContainer.h"

UShockActionClearContainer::UShockActionClearContainer()
{
	ActionClassName = TEXT("ActionClearContainer");
}

void UShockActionClearContainer::Configure(FName InContainer)
{
	ContainerLabel = InContainer;
}

bool UShockActionClearContainer::RequestClear()
{
	if (ContainerLabel.IsNone())
	{
		return false;
	}
	LastContainerLabel = ContainerLabel;
	return true;
}
