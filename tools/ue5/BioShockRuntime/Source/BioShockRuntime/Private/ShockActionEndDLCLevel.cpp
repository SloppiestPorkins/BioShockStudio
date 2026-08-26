#include "ShockActionEndDLCLevel.h"

UShockActionEndDLCLevel::UShockActionEndDLCLevel()
{
	ActionClassName = TEXT("ActionEndDLCLevel");
}

void UShockActionEndDLCLevel::Configure(bool bInFailed)
{
	bFailedLevel = bInFailed;
}

bool UShockActionEndDLCLevel::RequestEnd()
{
	bLastFailedLevel = bFailedLevel;
	return true;
}
