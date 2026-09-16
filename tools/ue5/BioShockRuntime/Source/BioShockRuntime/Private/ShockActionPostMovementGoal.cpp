#include "ShockActionPostMovementGoal.h"

#include "BaseShockAI.h"
#include "EngineUtils.h"

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

int32 UShockActionPostMovementGoal::ApplyInWorld(UWorld* World)
{
	if (!RequestPost() || !World)
	{
		return 0;
	}
	FVector Dest = FVector::ZeroVector;
	const FString WantDest = DestinationLabel.ToString();
	for (TActorIterator<AActor> It(World); It; ++It)
	{
		AActor* Actor = *It;
		if (!Actor)
		{
			continue;
		}
#if WITH_EDITOR
		if (Actor->GetActorLabel().Equals(WantDest, ESearchCase::CaseSensitive))
		{
			Dest = Actor->GetActorLocation();
			break;
		}
#endif
	}
	int32 Applied = 0;
	for (ABaseShockAI* AI : ABaseShockAI::CollectLabeled(World, TargetLabel))
	{
		AI->PostScriptedMovementGoal(DestinationLabel, GoalName, Priority, bShouldRun, Dest);
		++Applied;
	}
	return Applied;
}

bool UShockActionPostMovementGoal::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World) > 0;
}
