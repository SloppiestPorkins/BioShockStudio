#include "ShockActionStopSecurityAlarm.h"

#include "ShockPlayer.h"

UShockActionStopSecurityAlarm::UShockActionStopSecurityAlarm()
{
	ActionClassName = TEXT("ActionStopSecurityAlarm");
}

void UShockActionStopSecurityAlarm::Configure(bool bInDormant)
{
	bBotsBecomeDormant = bInDormant;
}

bool UShockActionStopSecurityAlarm::RequestStop()
{
	bLastBotsBecomeDormant = bBotsBecomeDormant;
	return true;
}

int32 UShockActionStopSecurityAlarm::ApplyInWorld(UWorld* World)
{
	if (!RequestStop() || !World)
	{
		return 0;
	}
	AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World);
	if (!Player)
	{
		return 0;
	}
	Player->SetSecurityAlarmOn(false, NAME_None);
	return 1;
}
