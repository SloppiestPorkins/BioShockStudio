#include "ShockActionRemoveGoal.h"

#include "BaseShockAI.h"

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

int32 UShockActionRemoveGoal::ApplyInWorld(UWorld* World)
{
	if (!RequestRemove())
	{
		return 0;
	}
	int32 Applied = 0;
	for (ABaseShockAI* AI : ABaseShockAI::CollectLabeled(World, TargetLabel))
	{
		if (!AI->MovementGoalName.Equals(GoalName, ESearchCase::CaseSensitive))
		{
			continue;
		}
		AI->MovementGoalName.Empty();
		AI->MovementDestinationLabel = NAME_None;
		++Applied;
	}
	return Applied;
}

bool UShockActionRemoveGoal::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World) > 0;
}
