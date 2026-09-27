#include "ShockScriptRunner.h"

#include "ShockAction.h"
#include "ShockActionBool.h"
#include "ShockActionCinematicFadeView.h"
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

bool UShockScriptRunner::MatchesMessageClass(FName MessageClassName) const
{
	// NAME_None = the importer couldn't/didn't resolve one: fall back to the old label-only
	// behaviour rather than silently stop a script that worked. "Message" is UE2's own base
	// class and accepts every message from the listed labels (23-Scripting-Examples.md).
	static const FName BaseMessage(TEXT("Message"));
	if (ScriptMessageClass.IsNone() || ScriptMessageClass == BaseMessage)
	{
		return true;
	}

	// A Script accepts its class AND every subclass (20-Scripting-Basics, scriptMessageClass).
	// Only the abstract/base classes the SDK names need a table: MessageTrigger (sent by
	// ActionSendTriggerMessage; base of the enter/exit classes), MessageTriggerVolume, MessageMover.
	static const TMap<FName, FName> Parent = {
		{FName(TEXT("MessageTriggerEnter")), FName(TEXT("MessageTrigger"))},
		{FName(TEXT("MessageTriggerExit")), FName(TEXT("MessageTrigger"))},
		{FName(TEXT("MessageTriggerVolume")), FName(TEXT("MessageTrigger"))},
		{FName(TEXT("MessageTriggerVolumeEnter")), FName(TEXT("MessageTriggerVolume"))},
		{FName(TEXT("MessageTriggerVolumeExit")), FName(TEXT("MessageTriggerVolume"))},
		{FName(TEXT("MessageMoverOpening")), FName(TEXT("MessageMover"))},
		{FName(TEXT("MessageMoverOpened")), FName(TEXT("MessageMover"))},
		{FName(TEXT("MessageMoverClosing")), FName(TEXT("MessageMover"))},
		{FName(TEXT("MessageMoverClosed")), FName(TEXT("MessageMover"))},
	};
	for (FName Walk = MessageClassName; !Walk.IsNone();)
	{
		if (Walk == ScriptMessageClass)
		{
			return true;
		}
		const FName* Up = Parent.Find(Walk);
		Walk = Up ? *Up : NAME_None;
	}
	return false;
}

void UShockScriptRunner::SetMessageFilterField(const FString& FieldName, const FString& Value)
{
	const FString Trimmed = Value.TrimStartAndEnd();
	if (FieldName.IsEmpty() || Trimmed.IsEmpty() || Trimmed.Equals(TEXT("None"), ESearchCase::IgnoreCase)
		|| Trimmed == TEXT("0"))
	{
		return;
	}
	MessageFilter.Add(FieldName.ToLower(), Trimmed);
}

bool UShockScriptRunner::MatchesMessageFilter(const TMap<FString, FString>& Fields) const
{
	for (const TPair<FString, FString>& Want : MessageFilter)
	{
		for (const TPair<FString, FString>& Have : Fields)
		{
			if (Have.Key.Equals(Want.Key, ESearchCase::IgnoreCase))
			{
				if (!Have.Value.TrimStartAndEnd().Equals(Want.Value, ESearchCase::IgnoreCase))
				{
					return false;
				}
				break;
			}
		}
	}
	return true;
}

bool UShockScriptRunner::TryStartFromMessage(FName MessageClassName, const FString& SourceLabel)
{
	return TryStartFromMessageWithFields(MessageClassName, SourceLabel, TMap<FString, FString>());
}

bool UShockScriptRunner::TryStartFromMessageWithFields(
	FName MessageClassName, const FString& SourceLabel, const TMap<FString, FString>& Fields)
{
	if (!bEnabled || !MatchesTriggeredBy(SourceLabel) || !MatchesMessageClass(MessageClassName)
		|| !MatchesMessageFilter(Fields))
	{
		return false;
	}
	if (bIsExecuting)
	{
		FQueuedMessage Queued;
		Queued.MessageClass = MessageClassName;
		Queued.SourceLabel = SourceLabel;
		Queued.Fields = Fields;
		MessageQueue.Add(Queued);
		return true;
	}
	LastMessageClass = MessageClassName;
	LastMessageSource = SourceLabel;
	return StartExecutionWithMessageFields(Fields);
}

FString UShockScriptRunner::GetLastMessageField(const FString& FieldName) const
{
	for (const TPair<FString, FString>& Pair : LastMessageFields)
	{
		if (Pair.Key.Equals(FieldName, ESearchCase::IgnoreCase))
		{
			return Pair.Value;
		}
	}
	return FString();
}

void UShockScriptRunner::SetEnabled(bool bInEnabled)
{
	bEnabled = bInEnabled;
	if (!bEnabled)
	{
		MessageQueue.Reset();
	}
}

void UShockScriptRunner::StartScriptTimer(float Seconds, float WorldTimeSeconds)
{
	if (Seconds <= 0.0f)
	{
		bTimerActive = false;
		TimerExpireAt = -1.0f;
		return;
	}
	bTimerActive = true;
	TimerExpireAt = WorldTimeSeconds + Seconds;
}

void UShockScriptRunner::StopScriptTimer()
{
	bTimerActive = false;
	TimerExpireAt = -1.0f;
}

void UShockScriptRunner::TickScriptTimer(float WorldTimeSeconds)
{
	if (!bTimerActive || TimerExpireAt < 0.0f || WorldTimeSeconds < TimerExpireAt)
	{
		return;
	}
	bTimerActive = false;
	TimerExpireAt = -1.0f;
	if (Registry)
	{
		Registry->DispatchMessage(FName(TEXT("MessageTimerExpired")), ScriptLabel.ToString());
	}
}

void UShockScriptRunner::SetRegistry(UShockScriptRegistry* InRegistry)
{
	Registry = InRegistry;
	if (Registry)
	{
		Registry->RegisterScript(this);
	}
	if (Variables)
	{
		Variables->BindRegistry(Registry);
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
	// Keep SCR-G06 dotted reads (`ScriptLabel.varname`) wired even if SetRegistry ran first.
	Variables->BindRegistry(Registry);
	return Variables;
}

bool UShockScriptRunner::BeginExecutionInternal(bool bClearMessageFields)
{
	if (bIsExecuting)
	{
		// Already running: refuse a second start (Blocking/NonBlocking ExecuteScript).
		return false;
	}
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
	if (bClearMessageFields)
	{
		LastMessageFields.Reset();
	}
	EnsureVariables();
	CurrentlyExecutingActionIndex = 0;
	ActionsCompleted = 0;
	bExitRequested = false;
	bWaitPrepared = false;
	bGoalWaitPrepared = false;
	bQuestLogWaitPrepared = false;
	bFadePrepared = false;
	PendingWait = nullptr;
	PendingGoalWait = nullptr;
	PendingQuestLogWait = nullptr;
	PendingAnimation = nullptr;
	PendingFade = nullptr;
	PendingChild = nullptr;
	SpawnedChildren.Reset();
	LoopStack.Reset();
	ForStack.Reset();
	bIsExecuting = true;
	return true;
}

bool UShockScriptRunner::StartExecution()
{
	return BeginExecutionInternal(/*bClearMessageFields=*/true);
}

bool UShockScriptRunner::StartExecutionWithMessageFields(const TMap<FString, FString>& Fields)
{
	LastMessageFields = Fields;
	return BeginExecutionInternal(/*bClearMessageFields=*/false);
}

void UShockScriptRunner::FinishExecution()
{
	// SCR-G18: value-producing action temps die when the list ends (not script/global vars).
	{
		TSet<UShockAction*> ClearVisited;
		for (const TObjectPtr<UShockAction>& Action : Actions)
		{
			ResetActionRuntimeState(Action, ClearVisited);
		}
	}
	bIsExecuting = false;
	PendingWait = nullptr;
	PendingGoalWait = nullptr;
	PendingQuestLogWait = nullptr;
	PendingAnimation = nullptr;
	PendingFade = nullptr;
	PendingChild = nullptr;
	bWaitPrepared = false;
	bGoalWaitPrepared = false;
	bQuestLogWaitPrepared = false;
	bFadePrepared = false;
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
	return StartExecutionWithMessageFields(Msg.Fields);
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
	TickScriptTimer(WorldTimeSeconds);

	while (true)
	{
		if (PendingFade)
		{
			if (!PendingFade->IsReady(WorldTimeSeconds))
			{
				TickSpawnedChildren(WorldTimeSeconds);
				return true;
			}
			PendingFade = nullptr;
			bFadePrepared = false;
			++CurrentlyExecutingActionIndex;
			++ActionsCompleted;
			continue;
		}

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
			if (PendingWait || PendingGoalWait || PendingQuestLogWait || PendingAnimation || PendingFade)
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
	return bIsExecuting || AnySpawnedChildExecuting() || bTimerActive;
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
	Ctx.MessageFields = &LastMessageFields;
	Ctx.WorldTimeSeconds = WorldTimeSeconds;

	// ActionWait remains on this index across ticks. Its parameters are resolved at entry, like
	// UnrealScript latentExecute(), rather than being rebound every frame while it is pending.
	if (!(Cast<UShockActionWait>(Action) && bWaitPrepared)
		&& !(Cast<UShockActionWaitForGoal>(Action) && bGoalWaitPrepared)
		&& !(Cast<UShockActionWaitForQuestLogToFinish>(Action) && bQuestLogWaitPrepared)
		&& !(Cast<UShockActionCinematicFadeView>(Action) && bFadePrepared))
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

	if (UShockActionCinematicFadeView* Fade = Cast<UShockActionCinematicFadeView>(Action))
	{
		if (!bFadePrepared)
		{
			Fade->ApplyInWorld(Ctx);
			Fade->PrepareWait(WorldTimeSeconds);
			PendingFade = Fade;
			bFadePrepared = true;
		}
		if (!Fade->IsReady(WorldTimeSeconds))
		{
			return false;
		}
		PendingFade = nullptr;
		bFadePrepared = false;
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
		// Empty TargetScript → current script only. A named target stops EVERY runner with
		// that label (Medical ships StandingOnCremationBody twice; registry keeps all).
		if (Exit->TargetScript.IsNone())
		{
			++ActionsCompleted;
			bExitRequested = true;
			FinishExecution();
			return false;
		}
		TArray<UShockScriptRunner*> Targets =
			Registry ? Registry->FindAllScripts(Exit->TargetScript) : TArray<UShockScriptRunner*>();
		bool bSelfAmongTargets = false;
		for (UShockScriptRunner* Target : Targets)
		{
			if (!Target)
			{
				continue;
			}
			if (Target == this)
			{
				bSelfAmongTargets = true;
				continue;
			}
			Target->FinishExecution();
		}
		++ActionsCompleted;
		if (bSelfAmongTargets)
		{
			bExitRequested = true;
			FinishExecution();
			return false;
		}
		++CurrentlyExecutingActionIndex;
		return true;
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
