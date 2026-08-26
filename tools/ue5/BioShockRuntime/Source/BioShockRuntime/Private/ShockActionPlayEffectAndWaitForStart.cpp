#include "ShockActionPlayEffectAndWaitForStart.h"

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
