#include "ShockActionStopEffect.h"

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
