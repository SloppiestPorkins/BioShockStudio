#include "ShockActionControlScriptedSequence.h"

UShockActionControlScriptedSequence::UShockActionControlScriptedSequence()
{
	ActionClassName = TEXT("ActionControlScriptedSequence");
}

void UShockActionControlScriptedSequence::Configure(FName InTargetLabel, int32 InRunNow)
{
	TargetLabel = InTargetLabel;
	RunNow = InRunNow;
}

bool UShockActionControlScriptedSequence::RequestControl()
{
	if (TargetLabel.IsNone())
	{
		return false;
	}
	LastTargetLabel = TargetLabel;
	LastRunNow = RunNow;
	return true;
}
