#include "ShockActionPlaceItemInContainerSlot.h"

UShockActionPlaceItemInContainerSlot::UShockActionPlaceItemInContainerSlot()
{
	ActionClassName = TEXT("ActionPlaceItemInContainerSlot");
}
void UShockActionPlaceItemInContainerSlot::ConfigureSlot(FName InContainer, int32 InSlot, bool bInOverwrite)
{
	ContainerLabel = InContainer;
	Slot = InSlot;
	bOverwriteExistingItem = bInOverwrite;
}
bool UShockActionPlaceItemInContainerSlot::RequestPlace()
{
	if (ContainerLabel.IsNone() || ItemClass.IsNone() || StackSize <= 0) return false;
	return Slot >= 0;
}
