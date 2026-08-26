#include "ShockActionSpawnPickup.h"

UShockActionSpawnPickup::UShockActionSpawnPickup()
{
	ActionClassName = TEXT("ActionSpawnPickup");
}

void UShockActionSpawnPickup::Configure(
	FName InActorLabel,
	FName InTarget,
	FName InPickupClass,
	FName InItemClass,
	int32 InStack,
	bool bInStartsPhysical)
{
	ActorLabel = InActorLabel;
	TargetActorLabel = InTarget;
	PickupClassName = InPickupClass;
	ItemClassName = InItemClass;
	StackSize = InStack;
	bStartsPhysical = bInStartsPhysical;
}

bool UShockActionSpawnPickup::RequestSpawn()
{
	if (TargetActorLabel.IsNone() || PickupClassName.IsNone())
	{
		return false;
	}
	LastTargetActorLabel = TargetActorLabel;
	return true;
}
