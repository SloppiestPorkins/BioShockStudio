#include "ShockActionPlaceItemInContainerSlot.h"

#include "ShockScriptReflection.h"
#include "ShockSearchableContainer.h"

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

int32 UShockActionPlaceItemInContainerSlot::ApplyInWorld(UWorld* World)
{
	if (!RequestPlace() || !World)
	{
		return 0;
	}
	AShockSearchableContainer* Container = Cast<AShockSearchableContainer>(
		ShockScriptReflection::ResolveTargetActor(World, ContainerLabel));
	if (!Container)
	{
		return 0;
	}
	return Container->PlaceItemInSlot(Slot, ItemClass, StackSize, bOverwriteExistingItem) ? 1 : 0;
}

bool UShockActionPlaceItemInContainerSlot::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World) > 0;
}
