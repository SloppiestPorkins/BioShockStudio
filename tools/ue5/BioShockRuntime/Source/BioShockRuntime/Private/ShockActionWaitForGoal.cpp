#include "ShockActionWaitForGoal.h"

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
