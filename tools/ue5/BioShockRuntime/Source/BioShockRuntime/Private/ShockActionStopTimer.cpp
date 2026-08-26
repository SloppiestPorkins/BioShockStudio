#include "ShockActionStopTimer.h"

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
