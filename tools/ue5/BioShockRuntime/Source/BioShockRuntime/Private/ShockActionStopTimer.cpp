#include "ShockActionStopTimer.h"

#include "ShockPlayer.h"

UShockActionStopTimer::UShockActionStopTimer()
{
	ActionClassName = TEXT("ActionStopTimer");
}

void UShockActionStopTimer::Configure(FName InScriptLabel)
{
	ScriptLabel = InScriptLabel;
}

bool UShockActionStopTimer::RequestStop()
{
	if (ScriptLabel.IsNone())
	{
		return false;
	}
	LastScriptLabel = ScriptLabel;
	return true;
}

int32 UShockActionStopTimer::ApplyInWorld(UWorld* World)
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
	Player->StopTimerForScript(ScriptLabel);
	return 1;
}
