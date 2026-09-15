#include "ShockActionPlayEffectAndWaitForStart.h"

#include "ShockEffectsSubsystem.h"
#include "ShockScriptReflection.h"

UShockActionPlayEffectAndWaitForStart::UShockActionPlayEffectAndWaitForStart()
{
	ActionClassName = TEXT("ActionPlayEffectAndWaitForStart");
}

void UShockActionPlayEffectAndWaitForStart::Configure(
	FName InEvent,
	FName InTag,
	float InTimeout,
	FName InActor,
	bool bInSlowStatic,
	bool bInLog)
{
	EffectEventToPlay = InEvent;
	EffectTag = InTag;
	TimeoutSeconds = InTimeout;
	ActorLabel = InActor;
	bSlowAlsoTriggerOnStaticActors = bInSlowStatic;
	bLogTriggerInfo = bInLog;
}

bool UShockActionPlayEffectAndWaitForStart::RequestPlay()
{
	if (EffectEventToPlay.IsNone())
	{
		return false;
	}
	LastEffectEventToPlay = EffectEventToPlay;
	return true;
}

bool UShockActionPlayEffectAndWaitForStart::ApplyInWorld(UWorld* World)
{
	if (!RequestPlay())
	{
		return false;
	}
	AActor* Target = ShockScriptReflection::ResolveTargetActor(World, ActorLabel);
	if (!Target)
	{
		return false;
	}
	if (UShockEffectsSubsystem* Fx = UShockEffectsSubsystem::Get(World))
	{
		Fx->PlayEffect(Target, EffectEventToPlay, EffectTag);
	}
	return true;
}

bool UShockActionPlayEffectAndWaitForStart::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World);
}
