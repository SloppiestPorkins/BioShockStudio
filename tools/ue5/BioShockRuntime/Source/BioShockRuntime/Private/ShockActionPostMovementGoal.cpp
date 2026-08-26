#include "ShockActionPostMovementGoal.h"

UShockActionPostMovementGoal::UShockActionPostMovementGoal()
{
	ActionClassName = TEXT("ActionPostMovementGoal");
	GoalName = TEXT("MovementGoal");
	Priority = 50;
}

void UShockActionPostMovementGoal::Configure(
	FName InTarget,
	FName InDestination,
	const FString& InGoalName,
	int32 InPriority,
	bool bInShouldRun)
{
	TargetLabel = InTarget;
	DestinationLabel = InDestination;
	GoalName = InGoalName;
	Priority = InPriority;
	bShouldRun = bInShouldRun;
}

bool UShockActionPostMovementGoal::RequestPost()
{
	if (TargetLabel.IsNone() || DestinationLabel.IsNone())
	{
		return false;
	}
	LastTargetLabel = TargetLabel;
	LastDestinationLabel = DestinationLabel;
	return true;
}
