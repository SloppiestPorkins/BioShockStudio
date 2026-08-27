#include "ShockActionStopEffect.h"

#include "EngineUtils.h"
#include "GameFramework/Actor.h"

UShockActionStopEffect::UShockActionStopEffect()
{
	ActionClassName = TEXT("ActionStopEffect");
	EffectEvent = FName(TEXT("ScriptTrigger"));
}

void UShockActionStopEffect::Configure(FName InEffectEvent, FName InEffectTag, FName InActorLabel)
{
	EffectEvent = InEffectEvent;
	EffectTag = InEffectTag;
	ActorLabel = InActorLabel;
}

bool UShockActionStopEffect::StopOnActor(AActor* Target)
{
	if (Target == nullptr || EffectEvent.IsNone())
	{
		return false;
	}
	LastStoppedEvent = EffectEvent;
	LastStoppedTag = EffectTag;
	LastStoppedActorName = Target->GetName();
	return true;
}

int32 UShockActionStopEffect::StopInWorld(UWorld* World)
{
	int32 Stopped = 0;
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
		if (StopOnActor(Actor))
		{
			++Stopped;
		}
#endif
	}
	return Stopped;
}
