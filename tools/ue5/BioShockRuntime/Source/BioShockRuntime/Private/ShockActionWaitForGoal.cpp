#include "ShockActionWaitForGoal.h"

#include "BaseShockAI.h"
#include "Engine/World.h"

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

bool UShockActionWaitForGoal::PrepareWait(UWorld* World, float WorldTimeSeconds)
{
	if (!RequestWait() || !World)
	{
		return false;
	}
	WaitStartedAt = WorldTimeSeconds;
	Result = -1;
	bLastSatisfied = false;
	return true;
}

bool UShockActionWaitForGoal::IsReady(UWorld* World, float WorldTimeSeconds)
{
	bool bFoundAI = false;
	bool bFoundActiveGoal = false;
	for (ABaseShockAI* AI : ABaseShockAI::CollectLabeled(World, TargetLabel))
	{
		bFoundAI = true;
		if (AI->HasCompletedMovementGoal(GoalName))
		{
			Result = 0;
			bLastSatisfied = true;
			SetReturnValueText(TEXT("0"), TEXT("VariableFloat"));
			return true;
		}
		if (AI->HasFailedMovementGoal(GoalName))
		{
			Result = 1;
			SetReturnValueText(TEXT("1"), TEXT("VariableFloat"));
			return true;
		}
		bFoundActiveGoal |= AI->MovementGoalName.Equals(GoalName, ESearchCase::CaseSensitive);
	}
	if (!bFoundAI || !bFoundActiveGoal)
	{
		Result = 1;
		SetReturnValueText(TEXT("1"), TEXT("VariableFloat"));
		return true;
	}
	if (TimeOut > 0.0f && WaitStartedAt >= 0.0f
		&& WorldTimeSeconds - WaitStartedAt >= TimeOut)
	{
		Result = 2;
		SetReturnValueText(TEXT("2"), TEXT("VariableFloat"));
		return true;
	}
	return false;
}

int32 UShockActionWaitForGoal::ApplyInWorld(UWorld* World)
{
	if (!World)
	{
		return 0;
	}
	const float Now = World->GetTimeSeconds();
	return PrepareWait(World, Now) && IsReady(World, Now) && Result == 0 ? 1 : 0;
}

bool UShockActionWaitForGoal::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World) > 0;
}
