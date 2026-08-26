#include "ShockActionHideOrShowActor.h"

#include "GameFramework/Actor.h"

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
