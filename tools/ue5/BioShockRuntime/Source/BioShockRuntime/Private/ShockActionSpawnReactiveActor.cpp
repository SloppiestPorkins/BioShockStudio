#include "ShockActionSpawnReactiveActor.h"

UShockActionSpawnReactiveActor::UShockActionSpawnReactiveActor()
{
	ActionClassName = TEXT("ActionSpawnReactiveActor");
}

void UShockActionSpawnReactiveActor::Configure(FName InActorLabel, FName InTarget, FName InClass, bool bInStartsPhysical)
{
	ActorLabel = InActorLabel;
	TargetActorLabel = InTarget;
	ReactiveActorClassName = InClass;
	bStartsPhysical = bInStartsPhysical;
}

bool UShockActionSpawnReactiveActor::RequestSpawn()
{
	if (TargetActorLabel.IsNone() || ReactiveActorClassName.IsNone())
	{
		return false;
	}
	LastTargetActorLabel = TargetActorLabel;
	return true;
}
