#include "ShockActionStopEffect.h"

#include "ShockEffectsSubsystem.h"
#include "ShockScriptReflection.h"

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

	if (UShockEffectsSubsystem* Fx = UShockEffectsSubsystem::Get(Target->GetWorld()))
	{
		Fx->StopEffect(Target, EffectEvent);
	}
	return true;
}

int32 UShockActionStopEffect::StopInWorld(UWorld* World)
{
	int32 Stopped = 0;
	if (!World || ActorLabel.IsNone())
	{
		return 0;
	}
	for (AActor* Actor : ShockScriptReflection::CollectActorsByLabel(World, ActorLabel))
	{
		if (StopOnActor(Actor))
		{
			++Stopped;
		}
	}
	return Stopped;
}

bool UShockActionStopEffect::ApplyInWorld(const FShockActionContext& Ctx)
{
	return StopInWorld(Ctx.World) > 0;
}
