#include "ShockScriptRunner.h"

#include "ShockAction.h"
#include "ShockActionExecuteScript.h"
#include "ShockActionExitLoop.h"
#include "ShockActionExitScript.h"
#include "ShockActionFor.h"
#include "ShockActionIf.h"
#include "ShockActionLoop.h"
#include "ShockActionScriptNote.h"
#include "ShockActionSendTriggerMessage.h"
#include "ShockActionVariableAssign.h"
#include "ShockActionVariableDecrement.h"
#include "ShockActionVariableIncrement.h"
#include "ShockActionWait.h"
#include "ShockScriptRegistry.h"
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

void UShockScriptRunner::SetTriggeredBy(const FString& InTriggeredBy)
{
	TriggeredBy = InTriggeredBy;
}

bool UShockScriptRunner::MatchesTriggeredBy(const FString& SourceLabel) const
{
	const FString Trimmed = TriggeredBy.TrimStartAndEnd();
	if (Trimmed.IsEmpty() || SourceLabel.IsEmpty())
	{
		// UC BeginPlay only registerMessage when TriggeredBy is non-empty.
		return false;
	}
	TArray<FString> Tokens;
	Trimmed.ParseIntoArray(Tokens, TEXT(","), true);
	for (FString& Token : Tokens)
	{
		Token = Token.TrimStartAndEnd();
		if (Token.Equals(SourceLabel, ESearchCase::IgnoreCase))
		{
			return true;
		}
	}
	return false;
}

bool UShockScriptRunner::TryStartFromMessage(FName MessageClassName, const FString& SourceLabel)
{
	if (!bEnabled || !MatchesTriggeredBy(SourceLabel))
	{
		return false;
	}
	if (bIsExecuting)
	{
		FQueuedMessage Queued;
		Queued.MessageClass = MessageClassName;
		Queued.SourceLabel = SourceLabel;
		MessageQueue.Add(Queued);
		return true;
	}
	LastMessageClass = MessageClassName;
	LastMessageSource = SourceLabel;
	return StartExecution();
}

void UShockScriptRunner::SetRegistry(UShockScriptRegistry* InRegistry)
{
	Registry = InRegistry;
	if (Registry)
	{
		Registry->RegisterScript(this);
	}
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
	PendingChild = nullptr;
	SpawnedChildren.Reset();
	LoopStack.Reset();
	bIsExecuting = true;
	return true;
}

void UShockScriptRunner::FinishExecution()
{
	bIsExecuting = false;
	PendingWait = nullptr;
	PendingChild = nullptr;
	bWaitPrepared = false;
	CurrentlyExecutingActionIndex = -1;
	RunQueue.Reset();
	LoopStack.Reset();
	TryDequeueAndStart();
}

bool UShockScriptRunner::TryDequeueAndStart()
{
	if (MessageQueue.Num() == 0 || !bEnabled)
	{
		return false;
	}
	const FQueuedMessage Msg = MessageQueue[0];
	MessageQueue.RemoveAt(0);
	LastMessageClass = Msg.MessageClass;
	LastMessageSource = Msg.SourceLabel;
	return StartExecution();
}

int32 UShockScriptRunner::InsertActionsAt(int32 InsertAt, const TArray<TObjectPtr<UShockAction>>& ToInsert)
{
	int32 Inserted = 0;
	int32 At = InsertAt;
	for (const TObjectPtr<UShockAction>& Action : ToInsert)
	{
		if (Action)
		{
			RunQueue.Insert(Action, At++);
			++Inserted;
		}
	}
	if (Inserted == 0)
	{
		return 0;
	}
	for (FLoopFrame& Frame : LoopStack)
	{
		if (Frame.BodyStartIndex >= InsertAt)
		{
			Frame.BodyStartIndex += Inserted;
		}
		if (Frame.BodyEndIndex >= InsertAt)
		{
			Frame.BodyEndIndex += Inserted;
		}
	}
	return Inserted;
}

bool UShockScriptRunner::ResolveLoopBoundaries()
{
	bool bRestarted = false;
	while (LoopStack.Num() > 0 && CurrentlyExecutingActionIndex == LoopStack.Last().BodyEndIndex)
	{
		FLoopFrame& Top = LoopStack.Last();
		if (Top.bKeepLooping && Top.Iteration < MaxLoopIterations)
		{
			++Top.Iteration;
			CurrentlyExecutingActionIndex = Top.BodyStartIndex;
			bRestarted = true;
			break;
		}
		LoopStack.Pop();
	}
	return bRestarted;
}

void UShockScriptRunner::TickSpawnedChildren(float WorldTimeSeconds)
{
	for (int32 i = SpawnedChildren.Num() - 1; i >= 0; --i)
	{
		UShockScriptRunner* Child = SpawnedChildren[i];
		if (!Child)
		{
			SpawnedChildren.RemoveAt(i);
			continue;
		}
		if (Child->bIsExecuting)
		{
			Child->TickExecution(WorldTimeSeconds);
		}
		if (!Child->bIsExecuting)
		{
			SpawnedChildren.RemoveAt(i);
		}
	}
}

bool UShockScriptRunner::AnySpawnedChildExecuting() const
{
	for (const TObjectPtr<UShockScriptRunner>& Child : SpawnedChildren)
	{
		if (Child && Child->bIsExecuting)
		{
			return true;
		}
	}
	return false;
}

bool UShockScriptRunner::TickExecution(float WorldTimeSeconds)
{
	while (true)
	{
		if (PendingChild)
		{
			if (PendingChild->bIsExecuting)
			{
				PendingChild->TickExecution(WorldTimeSeconds);
			}
			if (PendingChild->bIsExecuting)
			{
				TickSpawnedChildren(WorldTimeSeconds);
				return true;
			}
			PendingChild = nullptr;
			++CurrentlyExecutingActionIndex;
			++ActionsCompleted;
			continue;
		}

		if (!bIsExecuting)
		{
			break;
		}

		if (!StepOne(WorldTimeSeconds))
		{
			if (PendingChild)
			{
				continue;
			}
			// Blocked on Wait — leave until a later Tick with later WorldTime.
			if (PendingWait)
			{
				break;
			}
			// FinishExecution may have dequeued MessageQueue and restarted — step again
			// this frame so the new Wait gets PrepareWait at the finish time.
			if (bIsExecuting)
			{
				continue;
			}
			break;
		}
	}

	TickSpawnedChildren(WorldTimeSeconds);
	return bIsExecuting || AnySpawnedChildExecuting();
}

bool UShockScriptRunner::StepOne(float WorldTimeSeconds)
{
	ResolveLoopBoundaries();

	if (bExitRequested || CurrentlyExecutingActionIndex < 0 || CurrentlyExecutingActionIndex >= RunQueue.Num())
	{
		FinishExecution();
		return false;
	}

	// Past end of outer queue while loops still want to run — ResolveLoopBoundaries handles BodyEnd.
	if (CurrentlyExecutingActionIndex >= RunQueue.Num())
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

	if (UShockActionExitLoop* ExitLoop = Cast<UShockActionExitLoop>(Action))
	{
		ExitLoop->RequestExitLoop();
		if (LoopStack.Num() > 0)
		{
			FLoopFrame& Top = LoopStack.Last();
			Top.bKeepLooping = false;
			CurrentlyExecutingActionIndex = Top.BodyEndIndex;
			++ActionsCompleted;
			return true;
		}
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionLoop* Loop = Cast<UShockActionLoop>(Action))
	{
		Loop->RequestEnterLoop();
		const int32 InsertAt = CurrentlyExecutingActionIndex + 1;
		const int32 BodyStart = InsertAt;
		const int32 Inserted = InsertActionsAt(InsertAt, Loop->LoopActions);
		FLoopFrame Frame;
		Frame.Loop = Loop;
		Frame.BodyStartIndex = BodyStart;
		Frame.BodyEndIndex = BodyStart + Inserted;
		Frame.Iteration = 0;
		Frame.bKeepLooping = true;
		LoopStack.Add(Frame);
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionFor* ForAction = Cast<UShockActionFor>(Action))
	{
		// Counter VariableFloat iterations still open — expand forActions once per enter.
		ForAction->RequestEnterFor();
		InsertActionsAt(CurrentlyExecutingActionIndex + 1, ForAction->ForActions);
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionExecuteScript* Exec = Cast<UShockActionExecuteScript>(Action))
	{
		if (!Exec->RequestExecute())
		{
			++CurrentlyExecutingActionIndex;
			++ActionsCompleted;
			return true;
		}
		UShockScriptRunner* Child = Registry ? Registry->FindScript(Exec->TargetScript) : nullptr;
		if (!Child || Child == this)
		{
			++CurrentlyExecutingActionIndex;
			++ActionsCompleted;
			return true;
		}
		if (!Child->StartExecution())
		{
			++CurrentlyExecutingActionIndex;
			++ActionsCompleted;
			return true;
		}
		if (Exec->IsBlocking())
		{
			PendingChild = Child;
			return false;
		}
		SpawnedChildren.Add(Child);
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionSendTriggerMessage* Trig = Cast<UShockActionSendTriggerMessage>(Action))
	{
		Trig->DispatchVia(Registry, ScriptLabel);
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
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
		InsertActionsAt(CurrentlyExecutingActionIndex + 1, BranchActions);
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

	++CurrentlyExecutingActionIndex;
	++ActionsCompleted;
	return true;
}
