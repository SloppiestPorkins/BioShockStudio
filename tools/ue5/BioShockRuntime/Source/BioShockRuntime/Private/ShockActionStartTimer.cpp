#include "ShockActionStartTimer.h"

UShockActionStartTimer::UShockActionStartTimer()
{
	ActionClassName = TEXT("ActionStartTimer");
}

void UShockActionStartTimer::Configure(float InSeconds)
{
	Seconds = InSeconds;
}

bool UShockActionStartTimer::RequestStart()
{
	if (Seconds <= 0.0f)
	{
		return false;
	}
	LastSeconds = Seconds;
	return true;
}
