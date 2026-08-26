#include "ShockActionRemoveGoal.h"

UShockActionRemoveGoal::UShockActionRemoveGoal()
{
	ActionClassName = TEXT("ActionRemoveGoal");
}

void UShockActionRemoveGoal::Configure(FName InTarget, const FString& InGoalName)
{
	TargetLabel = InTarget;
	GoalName = InGoalName;
}

bool UShockActionRemoveGoal::RequestRemove()
{
	if (TargetLabel.IsNone() || GoalName.IsEmpty())
	{
		return false;
	}
	LastTargetLabel = TargetLabel;
	LastGoalName = GoalName;
	return true;
}
