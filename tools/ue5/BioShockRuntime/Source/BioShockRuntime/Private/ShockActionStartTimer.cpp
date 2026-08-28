#include "ShockActionStartTimer.h"

#include "ShockPlayer.h"

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

int32 UShockActionStartTimer::ApplyInWorld(UWorld* World)
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
	Player->SetPendingTimerSeconds(Seconds);
	return 1;
}
