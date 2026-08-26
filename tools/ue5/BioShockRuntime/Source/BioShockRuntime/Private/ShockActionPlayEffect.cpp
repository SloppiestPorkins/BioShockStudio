#include "ShockActionPlayEffect.h"

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
