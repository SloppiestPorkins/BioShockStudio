#include "ShockActionStopSecurityAlarm.h"

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
