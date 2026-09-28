#include "ShockActionPlayEffect.h"

#include "ShockEffectsSubsystem.h"
#include "ShockScriptReflection.h"

UShockActionPlayEffect::UShockActionPlayEffect()
{
	ActionClassName = TEXT("ActionPlayEffect");
	EffectEvent = FName(TEXT("ScriptTrigger"));
	bIsGameCritical = false;
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

	if (UShockEffectsSubsystem* Fx = UShockEffectsSubsystem::Get(Target->GetWorld()))
	{
		Fx->PlayEffect(Target, EffectEvent, EffectTag);
	}
	return true;
}

int32 UShockActionPlayEffect::FireInWorld(UWorld* World)
{
	int32 Fired = 0;
	if (!World || ActorLabel.IsNone())
	{
		return 0;
	}
	for (AActor* Actor : ShockScriptReflection::CollectActorsByLabel(World, ActorLabel))
	{
		if (FireOnActor(Actor))
		{
			++Fired;
		}
	}
	return Fired;
}

bool UShockActionPlayEffect::ApplyInWorld(const FShockActionContext& Ctx)
{
	return FireInWorld(Ctx.World) > 0;
}
