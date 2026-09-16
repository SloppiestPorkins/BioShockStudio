#include "ShockScriptRunner.h"

#include "ShockAction.h"
#include "ShockActionBool.h"
#include "ShockActionExecuteScript.h"
#include "ShockActionExitLoop.h"
#include "ShockActionExitScript.h"
#include "ShockActionFor.h"
#include "ShockActionIf.h"
#include "ShockActionLoop.h"
#include "ShockActionPlayAnimation.h"
#include "ShockActionSendTriggerMessage.h"
#include "ShockActionVariableAssign.h"
#include "ShockActionVariableDecrement.h"
#include "ShockActionVariableIncrement.h"
#include "ShockActionWait.h"
#include "ShockActionWaitForGoal.h"
#include "ShockActionWaitForQuestLogToFinish.h"
#include "ShockScriptRegistry.h"
#include "ShockVariableScope.h"

#include "GameFramework/Actor.h"
#include "Engine/World.h"

namespace
{
	void ResetActionRuntimeState(UShockAction* Action, TSet<UShockAction*>& Visited)
	{
		if (!Action || Visited.Contains(Action))
		{
			return;
		}
		Visited.Add(Action);
		Action->ClearReturnValue();
		for (const FShockParameterResolveInfo& Info : Action->ResolveInfoList)
		{
			ResetActionRuntimeState(Info.SourceAction, Visited);
		}
		if (UShockActionIf* IfAction = Cast<UShockActionIf>(Action))
		{
			for (UShockActionBool* Test : IfAction->TestsOr) ResetActionRuntimeState(Test, Visited);
			for (UShockAction* Child : IfAction->TrueActions) ResetActionRuntimeState(Child, Visited);
			for (UShockAction* Child : IfAction->ElseActions) ResetActionRuntimeState(Child, Visited);
		}
		else if (UShockActionLoop* Loop = Cast<UShockActionLoop>(Action))
		{
			for (UShockAction* Child : Loop->LoopActions) ResetActionRuntimeState(Child, Visited);
		}
		else if (UShockActionFor* ForAction = Cast<UShockActionFor>(Action))
		{
			for (UShockAction* Child : ForAction->ForActions) ResetActionRuntimeState(Child, Visited);
		}
	}
}

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
	TSet<UShockAction*> ResetVisited;
	for (const TObjectPtr<UShockAction>& Action : Actions)
	{
		if (Action)
		{
			ResetActionRuntimeState(Action, ResetVisited);
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
	bGoalWaitPrepared = false;
	bQuestLogWaitPrepared = false;
	PendingWait = nullptr;
	PendingGoalWait = nullptr;
	PendingQuestLogWait = nullptr;
	PendingAnimation = nullptr;
	PendingChild = nullptr;
	SpawnedChildren.Reset();
	LoopStack.Reset();
	ForStack.Reset();
	bIsExecuting = true;
	return true;
}

void UShockScriptRunner::FinishExecution()
{
	bIsExecuting = false;
	PendingWait = nullptr;
	PendingGoalWait = nullptr;
	PendingQuestLogWait = nullptr;
	PendingAnimation = nullptr;
	PendingChild = nullptr;
	bWaitPrepared = false;
	bGoalWaitPrepared = false;
	bQuestLogWaitPrepared = false;
	CurrentlyExecutingActionIndex = -1;
	RunQueue.Reset();
	LoopStack.Reset();
	ForStack.Reset();
	TryDequeueAndStart();
}

UWorld* UShockScriptRunner::GetOuterWorld() const
{
	if (const AActor* OuterActor = Cast<AActor>(GetOuter()))
	{
		return OuterActor->GetWorld();
	}
	return nullptr;
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
	for (FForFrame& Frame : ForStack)
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

bool UShockScriptRunner::ResolveForBoundaries()
{
	bool bRestarted = false;
	while (ForStack.Num() > 0 && CurrentlyExecutingActionIndex == ForStack.Last().BodyEndIndex)
	{
		FForFrame& Top = ForStack.Last();
		UShockActionFor* ForAction = Top.ForAction;
		if (!ForAction || Top.Iteration >= MaxLoopIterations)
		{
			ForStack.Pop();
			continue;
		}

		UShockVariableScope* Vars = EnsureVariables();
		float Counter = ForAction->BeginValue;
		FString CounterText = Vars->GetValueOrEmpty(ForAction->CounterName);
		if (!CounterText.IsEmpty())
		{
			LexFromString(Counter, *CounterText);
		}
		const float Next = Counter + 1.0f;
		if (Next <= ForAction->EndValue + KINDA_SMALL_NUMBER)
		{
			Vars->Set(ForAction->CounterName, LexToString(Next));
			++Top.Iteration;
			CurrentlyExecutingActionIndex = Top.BodyStartIndex;
			bRestarted = true;
			break;
		}
		ForStack.Pop();
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
		if (PendingAnimation)
		{
			if (!PendingAnimation->IsCompleteInWorld(GetOuterWorld()))
			{
				TickSpawnedChildren(WorldTimeSeconds);
				return true;
			}
			PendingAnimation = nullptr;
			++CurrentlyExecutingActionIndex;
			++ActionsCompleted;
			continue;
		}

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
			if (PendingWait || PendingGoalWait || PendingQuestLogWait || PendingAnimation)
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
	ResolveForBoundaries();

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

	FShockActionContext Ctx;
	Ctx.World = GetOuterWorld();
	Ctx.OwnerActor = Cast<AActor>(GetOuter());
	Ctx.Variables = EnsureVariables();
	Ctx.Instigator = nullptr;
	Ctx.SourceLabel = ScriptLabel;
	Ctx.MessageClass = LastMessageClass;
	Ctx.MessageSource = LastMessageSource;

	// ActionWait remains on this index across ticks. Its parameters are resolved at entry, like
	// UnrealScript latentExecute(), rather than being rebound every frame while it is pending.
	if (!(Cast<UShockActionWait>(Action) && bWaitPrepared)
		&& !(Cast<UShockActionWaitForGoal>(Action) && bGoalWaitPrepared)
		&& !(Cast<UShockActionWaitForQuestLogToFinish>(Action) && bQuestLogWaitPrepared))
	{
		const bool bResolved = Action->ResolveParameters(Ctx);
		if (!bResolved && !Action->ResolveInfoList.IsEmpty())
		{
			UE_LOG(LogTemp, Warning, TEXT("BIOSHOCK_RESOLVE %s incomplete"), *Action->ActionClassName);
		}
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

	if (UShockActionWaitForQuestLogToFinish* QuestWait =
		Cast<UShockActionWaitForQuestLogToFinish>(Action))
	{
		if (!bQuestLogWaitPrepared)
		{
			if (!QuestWait->PrepareWait(Ctx.World, WorldTimeSeconds))
			{
				++CurrentlyExecutingActionIndex;
				++ActionsCompleted;
				return true;
			}
			PendingQuestLogWait = QuestWait;
			bQuestLogWaitPrepared = true;
		}
		if (!QuestWait->IsReady(Ctx.World, WorldTimeSeconds))
		{
			return false;
		}
		PendingQuestLogWait = nullptr;
		bQuestLogWaitPrepared = false;
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionWaitForGoal* GoalWait = Cast<UShockActionWaitForGoal>(Action))
	{
		if (!bGoalWaitPrepared)
		{
			if (!GoalWait->PrepareWait(Ctx.World, WorldTimeSeconds))
			{
				++CurrentlyExecutingActionIndex;
				++ActionsCompleted;
				return true;
			}
			PendingGoalWait = GoalWait;
			bGoalWaitPrepared = true;
		}
		if (!GoalWait->IsReady(Ctx.World, WorldTimeSeconds))
		{
			return false;
		}
		PendingGoalWait = nullptr;
		bGoalWaitPrepared = false;
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionPlayAnimation* Animation = Cast<UShockActionPlayAnimation>(Action))
	{
		const bool bApplied = Animation->ApplyInWorld(Ctx);
		UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_ACTION %s applied=%d"), *Animation->ActionClassName, bApplied ? 1 : 0);
		if (bApplied
			&& Animation->ShouldWaitForCompletion()
			&& !Animation->IsCompleteInWorld(Ctx.World))
		{
			PendingAnimation = Animation;
			return false;
		}
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
		if (!ForAction->RequestEnterFor())
		{
			++CurrentlyExecutingActionIndex;
			++ActionsCompleted;
			return true;
		}
		UShockVariableScope* Vars = EnsureVariables();
		Vars->Set(ForAction->CounterName, LexToString(ForAction->BeginValue));
		const int32 InsertAt = CurrentlyExecutingActionIndex + 1;
		const int32 BodyStart = InsertAt;
		const int32 Inserted = InsertActionsAt(InsertAt, ForAction->ForActions);
		FForFrame Frame;
		Frame.ForAction = ForAction;
		Frame.BodyStartIndex = BodyStart;
		Frame.BodyEndIndex = BodyStart + Inserted;
		Frame.Iteration = 0;
		ForStack.Add(Frame);
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
		// testsOr entries are expression actions owned by ActionIf, not queue entries, so they
		// need the same pre-execute binding pass as ordinary actions.
		for (const TObjectPtr<UShockActionBool>& Test : IfAction->TestsOr)
		{
			if (Test)
			{
				Test->ResolveParameters(Ctx);
			}
		}
		const FString Branch = IfAction->ChooseBranch(Ctx.World);
		const TArray<TObjectPtr<UShockAction>>& BranchActions =
			Branch == TEXT("true") ? IfAction->TrueActions : IfAction->ElseActions;
		InsertActionsAt(CurrentlyExecutingActionIndex + 1, BranchActions);
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	const bool bApplied = Action->ApplyInWorld(Ctx);
	UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_ACTION %s applied=%d"), *Action->ActionClassName, bApplied ? 1 : 0);

	++CurrentlyExecutingActionIndex;
	++ActionsCompleted;
	return true;
}
