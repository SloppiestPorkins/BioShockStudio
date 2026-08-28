#include "ShockActionStartSecurityAlarm.h"

#include "ShockPlayer.h"

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

int32 UShockActionStartSecurityAlarm::ApplyInWorld(UWorld* World)
{
	if (!RequestStart() || !World)
	{
		return 0;
	}
	AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World);
	if (!Player)
	{
		return 0;
	}
	Player->SetSecurityAlarmOn(true, TargetLabel);
	return 1;
}
