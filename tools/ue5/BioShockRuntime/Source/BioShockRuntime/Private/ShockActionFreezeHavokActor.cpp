#include "ShockActionFreezeHavokActor.h"

#include "ShockPhysicsLibrary.h"

UShockActionFreezeHavokActor::UShockActionFreezeHavokActor()
{
	ActionClassName = TEXT("ActionFreezeHavokActor");
	bFreeze = true;
	bActivateWhenUnfreezing = true;
}

void UShockActionFreezeHavokActor::Configure(FName InTargetLabel, bool bInFreeze)
{
	TargetLabel = InTargetLabel;
	bFreeze = bInFreeze;
}

bool UShockActionFreezeHavokActor::ApplyToActor(AActor* Target)
{
	if (Target == nullptr)
	{
		return false;
	}
	const bool bApplied = UShockPhysicsLibrary::SetActorPhysicsFrozen(
		Target,
		bFreeze,
		!bFreeze && bActivateWhenUnfreezing);
	bLastAppliedFreeze = bFreeze;
	return bApplied;
}

int32 UShockActionFreezeHavokActor::ApplyInWorld(UWorld* World)
{
	if (!World || TargetLabel.IsNone())
	{
		return 0;
	}
	AActor* TargetActor = UShockPhysicsLibrary::FindActorByLabel(World, TargetLabel);
	if (!TargetActor)
	{
		return 0;
	}
	return ApplyToActor(TargetActor) ? 1 : 0;
}
