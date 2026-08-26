#include "ShockActionWait.h"

UShockActionWait::UShockActionWait()
{
	ActionClassName = TEXT("ActionWait");
	Seconds = 1.0f;
	WakeAtTime = -1.0f;
}

void UShockActionWait::PrepareWait(float WorldTimeSeconds)
{
	WakeAtTime = WorldTimeSeconds + Seconds;
}

bool UShockActionWait::IsReady(float WorldTimeSeconds) const
{
	return WakeAtTime >= 0.0f && WorldTimeSeconds >= WakeAtTime;
}
