#include "ShockActionHideOrShowActor.h"

#include "EngineUtils.h"
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

int32 UShockActionHideOrShowActor::ApplyInWorld(UWorld* World)
{
	int32 Applied = 0;
	if (!World || ActorLabel.IsNone())
	{
		return 0;
	}
	const FString Want = ActorLabel.ToString();
	for (TActorIterator<AActor> It(World); It; ++It)
	{
		AActor* Actor = *It;
		if (!Actor)
		{
			continue;
		}
#if WITH_EDITOR
		if (!Actor->GetActorLabel().Equals(Want, ESearchCase::CaseSensitive))
		{
			continue;
		}
		if (ApplyToActor(Actor))
		{
			++Applied;
		}
#endif
	}
	return Applied;
}
