#include "ShockActionStartSecurityAlarm.h"

UShockActionStartSecurityAlarm::UShockActionStartSecurityAlarm()
{
	ActionClassName = TEXT("ActionStartSecurityAlarm");
	NumSecurityBotsToSpawn = 1;
}

void UShockActionStartSecurityAlarm::Configure(
	FName InTarget,
	FName InBotClass,
	int32 InNumBots,
	bool bInForce,
	bool bInInfinite)
{
	TargetLabel = InTarget;
	SecurityBotClass = InBotClass;
	NumSecurityBotsToSpawn = InNumBots;
	bForceNewSecurityTarget = bInForce;
	bInfiniteAlarm = bInInfinite;
}

bool UShockActionStartSecurityAlarm::RequestStart()
{
	if (TargetLabel.IsNone())
	{
		return false;
	}
	LastTargetLabel = TargetLabel;
	return true;
}
