#include "ShockActionControlScriptedSequence.h"

#include "BaseShockAI.h"
#include "ShockPlayer.h"

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

int32 UShockActionControlScriptedSequence::ApplyInWorld(UWorld* World)
{
	if (!RequestControl())
	{
		return 0;
	}
	int32 Applied = 0;
	if (AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World))
	{
		Player->SetScriptedSequenceRunNow(TargetLabel, RunNow);
		++Applied;
	}
	for (ABaseShockAI* AI : ABaseShockAI::CollectLabeled(World, TargetLabel))
	{
		AI->ScriptedSequenceRunNow = RunNow;
		++Applied;
	}
	return Applied;
}
