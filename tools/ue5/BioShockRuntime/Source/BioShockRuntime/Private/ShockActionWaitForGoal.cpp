#include "ShockActionWaitForGoal.h"

#include "BaseShockAI.h"

UShockActionWaitForGoal::UShockActionWaitForGoal()
{
	ActionClassName = TEXT("ActionWaitForGoal");
}

void UShockActionWaitForGoal::Configure(FName InTarget, const FString& InGoalName, float InTimeOut)
{
	TargetLabel = InTarget;
	GoalName = InGoalName;
	TimeOut = InTimeOut;
}

bool UShockActionWaitForGoal::RequestWait()
{
	if (TargetLabel.IsNone() || GoalName.IsEmpty())
	{
		return false;
	}
	LastTargetLabel = TargetLabel;
	LastGoalName = GoalName;
	return true;
}

int32 UShockActionWaitForGoal::ApplyInWorld(UWorld* World)
{
	bLastSatisfied = false;
	if (!RequestWait())
	{
		return 0;
	}
	int32 Applied = 0;
	for (ABaseShockAI* AI : ABaseShockAI::CollectLabeled(World, TargetLabel))
	{
		if (AI->MovementGoalName == GoalName)
		{
			AI->bWaitForGoalSatisfied = true;
			bLastSatisfied = true;
			++Applied;
		}
	}
	return Applied;
}
