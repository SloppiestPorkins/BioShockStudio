#include "ShockActionWaitForCriticalMessageStart.h"

UShockActionWaitForCriticalMessageStart::UShockActionWaitForCriticalMessageStart()
{
	ActionClassName = TEXT("ActionWaitForCriticalMessageStart");
}

void UShockActionWaitForCriticalMessageStart::Configure(FName InEvent, float InTimeout, FName InActor)
{
	EffectEventToWaitFor = InEvent;
	TimeoutSeconds = InTimeout;
	ActorLabel = InActor;
}

bool UShockActionWaitForCriticalMessageStart::RequestWait()
{
	if (EffectEventToWaitFor.IsNone())
	{
		return false;
	}
	LastEffectEventToWaitFor = EffectEventToWaitFor;
	return true;
}
