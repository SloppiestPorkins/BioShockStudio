#include "ShockActionPlayEffect.h"

#include "EngineUtils.h"
#include "GameFramework/Actor.h"

UShockActionPlayEffect::UShockActionPlayEffect()
{
	ActionClassName = TEXT("ActionPlayEffect");
	EffectEvent = FName(TEXT("ScriptTrigger"));
}

void UShockActionPlayEffect::Configure(FName InEffectEvent, FName InEffectTag, FName InActorLabel)
{
	EffectEvent = InEffectEvent;
	EffectTag = InEffectTag;
	ActorLabel = InActorLabel;
}

bool UShockActionPlayEffect::FireOnActor(AActor* Target)
{
	if (!Target || EffectEvent.IsNone())
	{
		return false;
	}

	LastFiredEvent = EffectEvent;
	LastFiredTag = EffectTag;
	LastFiredActorName = Target->GetName();
	return true;
}

int32 UShockActionPlayEffect::FireInWorld(UWorld* World)
{
	int32 Fired = 0;
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
		if (FireOnActor(Actor))
		{
			++Fired;
		}
#endif
	}
	return Fired;
}
