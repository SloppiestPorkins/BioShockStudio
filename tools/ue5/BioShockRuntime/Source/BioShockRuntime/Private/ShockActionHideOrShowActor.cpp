#include "ShockActionHideOrShowActor.h"

#include "ShockScriptReflection.h"

UShockActionHideOrShowActor::UShockActionHideOrShowActor()
{
	ActionClassName = TEXT("ActionHideOrShowActor");
	bHideActor = true;
}

void UShockActionHideOrShowActor::Configure(FName InActorLabel, bool bInHideActor)
{
	ActorLabel = InActorLabel;
	bHideActor = bInHideActor;
}

bool UShockActionHideOrShowActor::ApplyToActor(AActor* Target)
{
	bLastApplySucceeded = false;
	if (Target == nullptr)
	{
		return false;
	}
	Target->SetActorHiddenInGame(bHideActor);
#if WITH_EDITOR
	Target->SetIsTemporarilyHiddenInEditor(bHideActor);
#endif
	bLastAppliedHide = bHideActor;
	bLastApplySucceeded = true;
	return true;
}

int32 UShockActionHideOrShowActor::ApplyInWorld(UWorld* World)
{
	int32 Applied = 0;
	if (!World || ActorLabel.IsNone())
	{
		return 0;
	}
	for (AActor* Actor : ShockScriptReflection::CollectActorsByLabel(World, ActorLabel))
	{
		if (ApplyToActor(Actor))
		{
			++Applied;
		}
	}
	return Applied;
}

bool UShockActionHideOrShowActor::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World) > 0;
}
