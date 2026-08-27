#include "ShockScriptRunner.h"

#include "ShockAction.h"
#include "ShockActionExitScript.h"
#include "ShockActionIf.h"
#include "ShockActionScriptNote.h"
#include "ShockActionVariableAssign.h"
#include "ShockActionVariableDecrement.h"
#include "ShockActionVariableIncrement.h"
#include "ShockActionWait.h"
#include "ShockVariableScope.h"

UShockScriptRunner::UShockScriptRunner()
{
	ScriptLabel = NAME_None;
	bEnabled = true;
}

void UShockScriptRunner::Configure(FName InLabel)
{
	ScriptLabel = InLabel;
}

void UShockScriptRunner::AddAction(UShockAction* Action)
{
	if (Action)
	{
		Actions.Add(Action);
	}
}

UShockVariableScope* UShockScriptRunner::EnsureVariables()
{
	if (!Variables)
	{
		Variables = NewObject<UShockVariableScope>(this);
	}
	return Variables;
}

bool UShockScriptRunner::StartExecution()
{
	if (!bEnabled || Actions.Num() == 0)
	{
		return false;
	}
	RunQueue.Reset();
	for (const TObjectPtr<UShockAction>& Action : Actions)
	{
		if (Action)
		{
			RunQueue.Add(Action);
		}
	}
	if (RunQueue.Num() == 0)
	{
		return false;
	}
	EnsureVariables();
	CurrentlyExecutingActionIndex = 0;
	ActionsCompleted = 0;
	bExitRequested = false;
	bWaitPrepared = false;
	PendingWait = nullptr;
	bIsExecuting = true;
	return true;
}

void UShockScriptRunner::FinishExecution()
{
	bIsExecuting = false;
	PendingWait = nullptr;
	bWaitPrepared = false;
	CurrentlyExecutingActionIndex = -1;
	RunQueue.Reset();
}

bool UShockScriptRunner::TickExecution(float WorldTimeSeconds)
{
	if (!bIsExecuting)
	{
		return false;
	}
	while (bIsExecuting)
	{
		if (!StepOne(WorldTimeSeconds))
		{
			break;
		}
	}
	return bIsExecuting;
}

bool UShockScriptRunner::StepOne(float WorldTimeSeconds)
{
	if (bExitRequested || CurrentlyExecutingActionIndex < 0 || CurrentlyExecutingActionIndex >= RunQueue.Num())
	{
		FinishExecution();
		return false;
	}

	UShockAction* Action = RunQueue[CurrentlyExecutingActionIndex];
	if (!Action)
	{
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionWait* Wait = Cast<UShockActionWait>(Action))
	{
		if (!bWaitPrepared)
		{
			Wait->PrepareWait(WorldTimeSeconds);
			PendingWait = Wait;
			bWaitPrepared = true;
		}
		if (!Wait->IsReady(WorldTimeSeconds))
		{
			return false;
		}
		PendingWait = nullptr;
		bWaitPrepared = false;
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionExitScript* Exit = Cast<UShockActionExitScript>(Action))
	{
		Exit->RequestExit();
		bExitRequested = true;
		++ActionsCompleted;
		FinishExecution();
		return false;
	}

	if (UShockActionVariableAssign* Assign = Cast<UShockActionVariableAssign>(Action))
	{
		Assign->ApplyToScope(EnsureVariables());
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionVariableIncrement* Inc = Cast<UShockActionVariableIncrement>(Action))
	{
		Inc->ApplyToScope(EnsureVariables());
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionVariableDecrement* Dec = Cast<UShockActionVariableDecrement>(Action))
	{
		Dec->ApplyToScope(EnsureVariables());
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionIf* IfAction = Cast<UShockActionIf>(Action))
	{
		const FString Branch = IfAction->ChooseBranch();
		const TArray<TObjectPtr<UShockAction>>& BranchActions =
			Branch == TEXT("true") ? IfAction->TrueActions : IfAction->ElseActions;
		int32 InsertAt = CurrentlyExecutingActionIndex + 1;
		for (const TObjectPtr<UShockAction>& BranchAction : BranchActions)
		{
			if (BranchAction)
			{
				RunQueue.Insert(BranchAction, InsertAt++);
			}
		}
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (Cast<UShockActionScriptNote>(Action))
	{
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	// Unknown / request-record-only action: step over.
	++CurrentlyExecutingActionIndex;
	++ActionsCompleted;
	return true;
}
