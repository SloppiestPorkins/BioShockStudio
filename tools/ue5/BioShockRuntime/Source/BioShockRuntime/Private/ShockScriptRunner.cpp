#include "ShockScriptRunner.h"

#include "ShockAction.h"
#include "ShockActionAttackTarget.h"
#include "ShockActionDestroyActor.h"
#include "ShockActionExecuteScript.h"
#include "ShockActionExitLoop.h"
#include "ShockActionExitScript.h"
#include "ShockActionFor.h"
#include "ShockActionHideOrShowActor.h"
#include "ShockActionIf.h"
#include "ShockActionLoop.h"
#include "ShockActionPlayAnimation.h"
#include "ShockActionPlayEffect.h"
#include "ShockActionScriptNote.h"
#include "ShockActionSendTriggerMessage.h"
#include "ShockActionSetProperty.h"
#include "ShockActionSpawnAI.h"
#include "ShockActionStopEffect.h"
#include "ShockActionLog.h"
#include "ShockActionLockDoor.h"
#include "ShockActionOpenDoor.h"
#include "ShockActionCloseDoor.h"
#include "ShockActionUnlockDoor.h"
#include "ShockActionTeleportPawnToLocation.h"
#include "ShockActionFreezeHavokActor.h"
#include "ShockActionSetActorLabel.h"
#include "ShockActionGiveItemsToPlayer.h"
#include "ShockActionRemoveItemsFromPlayer.h"
#include "ShockActionDisplayMapHUDRegion.h"
#include "ShockActionPrintClientMessage.h"
#include "ShockActionSetQuestHint.h"
#include "ShockActionInitiateQuest.h"
#include "ShockActionCompleteQuest.h"
#include "ShockActionCompleteQuestObjective.h"
#include "ShockActionFailQuest.h"
#include "ShockActionAutoSave.h"
#include "ShockActionDealDamage.h"
#include "ShockActionChangeLevel.h"
#include "ShockActionForcePlayerCrouch.h"
#include "ShockActionDisablePlayerMovement.h"
#include "ShockActionDealDamageInRadius.h"
#include "ShockActionApplyImpulse.h"
#include "ShockActionStartTimer.h"
#include "ShockActionStopTimer.h"
#include "ShockActionRunConsoleCommand.h"
#include "ShockActionChangeStaticMesh.h"
#include "ShockActionSetAIState.h"
#include "ShockActionToggleAIAttacking.h"
#include "ShockActionRagdoll.h"
#include "ShockActionSpawnPickup.h"
#include "ShockActionSpawnTurret.h"
#include "ShockActionAssertFact.h"
#include "ShockActionRetractFact.h"
#include "ShockActionForcePlayerMove.h"
#include "ShockActionTellAIToWait.h"
#include "ShockActionTellAIToContinue.h"
#include "ShockActionSetLightProperties.h"
#include "ShockActionChangeCollision.h"
#include "ShockActionStartSecurityAlarm.h"
#include "ShockActionStopSecurityAlarm.h"
#include "ShockActionSetDoorBrokenState.h"
#include "ShockActionHackTurret.h"
#include "ShockActionHackSecuritySystem.h"
#include "ShockActionPlayHUD.h"
#include "ShockActionStopHUD.h"
#include "ShockActionSetMaterialSwitchIndex.h"
#include "ShockActionTweakAIVision.h"
#include "ShockActionTweakAIHearing.h"
#include "ShockActionSetTipPriority.h"
#include "ShockActionMuteAI.h"
#include "ShockActionCinematicFadeView.h"
#include "ShockActionChangeSkinAtIndex.h"
#include "ShockActionAISpeech.h"
#include "ShockActionPostMovementGoal.h"
#include "ShockActionDisableOrEnableConcept.h"
#include "ShockActionControlScriptedSequence.h"
#include "ShockActionWaitForGoal.h"
#include "ShockActionSetOrUnsetInputContext.h"
#include "ShockActionChangePressure.h"
#include "ShockActionManipulateSpawnZoneRepopulation.h"
#include "ShockActionSetMovableSpotlightTarget.h"
#include "ShockActionSetMovableSpotlightState.h"
#include "ShockActionWaitForQuestLogToFinish.h"
#include "ShockActionToggleAIReactions.h"
#include "ShockActionDisplayOnScreenDebugMessage.h"
#include "ShockActionSetPlayerInvincibility.h"
#include "ShockActionSetAIPatrol.h"
#include "ShockActionChangePawnPhysics.h"
#include "ShockActionSetPawnInvincibility.h"
#include "ShockActionSetAINormalLODOverrideTime.h"
#include "ShockActionVariableAssign.h"
#include "ShockActionVariableDecrement.h"
#include "ShockActionVariableIncrement.h"
#include "ShockActionWait.h"
#include "ShockScriptRegistry.h"
#include "ShockVariableScope.h"

#include "GameFramework/Actor.h"
#include "Engine/World.h"

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
	ForStack.Reset();
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
		UWorld* World = nullptr;
		if (const UObject* OuterObj = GetOuter())
		{
			if (const AActor* OuterActor = Cast<AActor>(OuterObj))
			{
				World = OuterActor->GetWorld();
			}
		}
		const FString Branch = IfAction->ChooseBranch(World);
		const TArray<TObjectPtr<UShockAction>>& BranchActions =
			Branch == TEXT("true") ? IfAction->TrueActions : IfAction->ElseActions;
		InsertActionsAt(CurrentlyExecutingActionIndex + 1, BranchActions);
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionHideOrShowActor* HideShow = Cast<UShockActionHideOrShowActor>(Action))
	{
		UWorld* World = nullptr;
		if (const AActor* OuterActor = Cast<AActor>(GetOuter()))
		{
			World = OuterActor->GetWorld();
		}
		HideShow->ApplyInWorld(World);
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionSetProperty* SetProp = Cast<UShockActionSetProperty>(Action))
	{
		UWorld* World = nullptr;
		if (const AActor* OuterActor = Cast<AActor>(GetOuter()))
		{
			World = OuterActor->GetWorld();
		}
		SetProp->ApplyInWorld(World);
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionDestroyActor* Destroy = Cast<UShockActionDestroyActor>(Action))
	{
		UWorld* World = nullptr;
		if (const AActor* OuterActor = Cast<AActor>(GetOuter()))
		{
			World = OuterActor->GetWorld();
		}
		Destroy->DestroyInWorld(World);
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionPlayEffect* PlayFx = Cast<UShockActionPlayEffect>(Action))
	{
		UWorld* World = nullptr;
		if (const AActor* OuterActor = Cast<AActor>(GetOuter()))
		{
			World = OuterActor->GetWorld();
		}
		PlayFx->FireInWorld(World);
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionStopEffect* StopFx = Cast<UShockActionStopEffect>(Action))
	{
		UWorld* World = nullptr;
		if (const AActor* OuterActor = Cast<AActor>(GetOuter()))
		{
			World = OuterActor->GetWorld();
		}
		StopFx->StopInWorld(World);
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionSpawnAI* SpawnAI = Cast<UShockActionSpawnAI>(Action))
	{
		UWorld* World = nullptr;
		if (const AActor* OuterActor = Cast<AActor>(GetOuter()))
		{
			World = OuterActor->GetWorld();
		}
		SpawnAI->SpawnInWorld(World);
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionAttackTarget* Attack = Cast<UShockActionAttackTarget>(Action))
	{
		UWorld* World = nullptr;
		if (const AActor* OuterActor = Cast<AActor>(GetOuter()))
		{
			World = OuterActor->GetWorld();
		}
		Attack->ApplyInWorld(World);
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionPlayAnimation* PlayAnim = Cast<UShockActionPlayAnimation>(Action))
	{
		UWorld* World = nullptr;
		if (const AActor* OuterActor = Cast<AActor>(GetOuter()))
		{
			World = OuterActor->GetWorld();
		}
		PlayAnim->PlayInWorld(World);
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionLog* LogAction = Cast<UShockActionLog>(Action))
	{
		LogAction->Emit();
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionOpenDoor* OpenDoor = Cast<UShockActionOpenDoor>(Action))
	{
		OpenDoor->RequestOpen();
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionCloseDoor* CloseDoor = Cast<UShockActionCloseDoor>(Action))
	{
		CloseDoor->RequestClose();
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionLockDoor* LockDoor = Cast<UShockActionLockDoor>(Action))
	{
		LockDoor->RequestLock();
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionUnlockDoor* UnlockDoor = Cast<UShockActionUnlockDoor>(Action))
	{
		UnlockDoor->RequestUnlock();
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionTeleportPawnToLocation* Teleport = Cast<UShockActionTeleportPawnToLocation>(Action))
	{
		UWorld* World = nullptr;
		if (const AActor* OuterActor = Cast<AActor>(GetOuter()))
		{
			World = OuterActor->GetWorld();
		}
		Teleport->TeleportInWorld(World);
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionFreezeHavokActor* Freeze = Cast<UShockActionFreezeHavokActor>(Action))
	{
		UWorld* World = nullptr;
		if (const AActor* OuterActor = Cast<AActor>(GetOuter()))
		{
			World = OuterActor->GetWorld();
		}
		Freeze->ApplyInWorld(World);
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionSetActorLabel* SetLabel = Cast<UShockActionSetActorLabel>(Action))
	{
		UWorld* World = nullptr;
		if (const AActor* OuterActor = Cast<AActor>(GetOuter()))
		{
			World = OuterActor->GetWorld();
		}
		SetLabel->ApplyInWorld(World);
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionGiveItemsToPlayer* Give = Cast<UShockActionGiveItemsToPlayer>(Action))
	{
		UWorld* World = nullptr;
		if (const AActor* OuterActor = Cast<AActor>(GetOuter()))
		{
			World = OuterActor->GetWorld();
		}
		Give->ApplyInWorld(World);
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionRemoveItemsFromPlayer* Remove = Cast<UShockActionRemoveItemsFromPlayer>(Action))
	{
		Remove->ApplyInWorld(GetOuterWorld());
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionDisplayMapHUDRegion* MapHud = Cast<UShockActionDisplayMapHUDRegion>(Action))
	{
		MapHud->RequestDisplay();
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionPrintClientMessage* PrintMsg = Cast<UShockActionPrintClientMessage>(Action))
	{
		PrintMsg->RequestPrint();
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionSetQuestHint* QuestHint = Cast<UShockActionSetQuestHint>(Action))
	{
		QuestHint->RequestSet();
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionInitiateQuest* InitQuest = Cast<UShockActionInitiateQuest>(Action))
	{
		InitQuest->RequestInitiate();
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionCompleteQuestObjective* CompleteObj = Cast<UShockActionCompleteQuestObjective>(Action))
	{
		CompleteObj->RequestComplete();
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionCompleteQuest* CompleteQuest = Cast<UShockActionCompleteQuest>(Action))
	{
		CompleteQuest->RequestComplete();
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionFailQuest* FailQuest = Cast<UShockActionFailQuest>(Action))
	{
		FailQuest->RequestFail();
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionAutoSave* AutoSave = Cast<UShockActionAutoSave>(Action))
	{
		AutoSave->RequestSave();
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionDealDamage* DealDmg = Cast<UShockActionDealDamage>(Action))
	{
		UWorld* World = nullptr;
		if (const AActor* OuterActor = Cast<AActor>(GetOuter()))
		{
			World = OuterActor->GetWorld();
		}
		DealDmg->ApplyInWorld(World);
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionChangeLevel* ChangeLevel = Cast<UShockActionChangeLevel>(Action))
	{
		ChangeLevel->RequestChange();
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionForcePlayerCrouch* Crouch = Cast<UShockActionForcePlayerCrouch>(Action))
	{
		Crouch->ApplyInWorld(GetOuterWorld());
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionDisablePlayerMovement* DisableMove = Cast<UShockActionDisablePlayerMovement>(Action))
	{
		DisableMove->ApplyInWorld(GetOuterWorld());
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionDealDamageInRadius* RadiusDmg = Cast<UShockActionDealDamageInRadius>(Action))
	{
		UWorld* World = nullptr;
		if (const AActor* OuterActor = Cast<AActor>(GetOuter()))
		{
			World = OuterActor->GetWorld();
		}
		RadiusDmg->ApplyInWorld(World);
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionApplyImpulse* Impulse = Cast<UShockActionApplyImpulse>(Action))
	{
		UWorld* World = nullptr;
		if (const AActor* OuterActor = Cast<AActor>(GetOuter()))
		{
			World = OuterActor->GetWorld();
		}
		Impulse->ApplyInWorld(World);
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionStartTimer* StartTimer = Cast<UShockActionStartTimer>(Action))
	{
		StartTimer->RequestStart();
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionStopTimer* StopTimer = Cast<UShockActionStopTimer>(Action))
	{
		StopTimer->RequestStop();
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionRunConsoleCommand* Console = Cast<UShockActionRunConsoleCommand>(Action))
	{
		Console->ApplyInWorld(GetOuterWorld());
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionChangeStaticMesh* ChangeMesh = Cast<UShockActionChangeStaticMesh>(Action))
	{
		ChangeMesh->RequestChange();
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionSetAIState* AIState = Cast<UShockActionSetAIState>(Action))
	{
		AIState->ApplyInWorld(GetOuterWorld());
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionToggleAIAttacking* ToggleAttack = Cast<UShockActionToggleAIAttacking>(Action))
	{
		ToggleAttack->ApplyInWorld(GetOuterWorld());
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionRagdoll* Ragdoll = Cast<UShockActionRagdoll>(Action))
	{
		UWorld* World = nullptr;
		if (const AActor* OuterActor = Cast<AActor>(GetOuter()))
		{
			World = OuterActor->GetWorld();
		}
		Ragdoll->ApplyInWorld(World);
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionSpawnPickup* Pickup = Cast<UShockActionSpawnPickup>(Action))
	{
		Pickup->RequestSpawn();
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionSpawnTurret* Turret = Cast<UShockActionSpawnTurret>(Action))
	{
		Turret->RequestSpawn();
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionAssertFact* Assert = Cast<UShockActionAssertFact>(Action))
	{
		Assert->ApplyInWorld(GetOuterWorld());
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionRetractFact* Retract = Cast<UShockActionRetractFact>(Action))
	{
		Retract->ApplyInWorld(GetOuterWorld());
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionForcePlayerMove* ForceMove = Cast<UShockActionForcePlayerMove>(Action))
	{
		ForceMove->ApplyInWorld(GetOuterWorld());
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionTellAIToWait* WaitAI = Cast<UShockActionTellAIToWait>(Action))
	{
		WaitAI->ApplyInWorld(GetOuterWorld());
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionTellAIToContinue* ContinueAI = Cast<UShockActionTellAIToContinue>(Action))
	{
		ContinueAI->ApplyInWorld(GetOuterWorld());
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionSetLightProperties* Light = Cast<UShockActionSetLightProperties>(Action))
	{
		UWorld* World = nullptr;
		if (const AActor* OuterActor = Cast<AActor>(GetOuter()))
		{
			World = OuterActor->GetWorld();
		}
		Light->ApplyInWorld(World);
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionChangeCollision* Collision = Cast<UShockActionChangeCollision>(Action))
	{
		UWorld* World = nullptr;
		if (const AActor* OuterActor = Cast<AActor>(GetOuter()))
		{
			World = OuterActor->GetWorld();
		}
		Collision->ApplyInWorld(World);
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionStartSecurityAlarm* StartAlarm = Cast<UShockActionStartSecurityAlarm>(Action))
	{
		StartAlarm->RequestStart();
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionStopSecurityAlarm* StopAlarm = Cast<UShockActionStopSecurityAlarm>(Action))
	{
		StopAlarm->RequestStop();
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionSetDoorBrokenState* DoorBroken = Cast<UShockActionSetDoorBrokenState>(Action))
	{
		DoorBroken->RequestSet();
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionHackTurret* HackTurret = Cast<UShockActionHackTurret>(Action))
	{
		HackTurret->RequestHack();
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionHackSecuritySystem* HackSec = Cast<UShockActionHackSecuritySystem>(Action))
	{
		HackSec->RequestHack();
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionPlayHUD* PlayHud = Cast<UShockActionPlayHUD>(Action))
	{
		PlayHud->RequestPlay();
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionStopHUD* StopHud = Cast<UShockActionStopHUD>(Action))
	{
		StopHud->RequestStop();
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionSetMaterialSwitchIndex* MatSwitch = Cast<UShockActionSetMaterialSwitchIndex>(Action))
	{
		MatSwitch->RequestSet();
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionTweakAIVision* TweakVision = Cast<UShockActionTweakAIVision>(Action))
	{
		TweakVision->ApplyInWorld(GetOuterWorld());
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionTweakAIHearing* TweakHearing = Cast<UShockActionTweakAIHearing>(Action))
	{
		TweakHearing->ApplyInWorld(GetOuterWorld());
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionSetTipPriority* TipPriority = Cast<UShockActionSetTipPriority>(Action))
	{
		TipPriority->ApplyInWorld(GetOuterWorld());
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionMuteAI* MuteAI = Cast<UShockActionMuteAI>(Action))
	{
		MuteAI->ApplyInWorld(GetOuterWorld());
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionCinematicFadeView* FadeView = Cast<UShockActionCinematicFadeView>(Action))
	{
		FadeView->RequestFade();
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionChangeSkinAtIndex* ChangeSkin = Cast<UShockActionChangeSkinAtIndex>(Action))
	{
		ChangeSkin->RequestChangeSkin();
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionAISpeech* AISpeech = Cast<UShockActionAISpeech>(Action))
	{
		AISpeech->RequestSpeech();
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionPostMovementGoal* PostGoal = Cast<UShockActionPostMovementGoal>(Action))
	{
		PostGoal->ApplyInWorld(GetOuterWorld());
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionDisableOrEnableConcept* Concept = Cast<UShockActionDisableOrEnableConcept>(Action))
	{
		Concept->ApplyInWorld(GetOuterWorld());
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionControlScriptedSequence* ScriptedSeq = Cast<UShockActionControlScriptedSequence>(Action))
	{
		ScriptedSeq->ApplyInWorld(GetOuterWorld());
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionWaitForGoal* WaitGoal = Cast<UShockActionWaitForGoal>(Action))
	{
		WaitGoal->ApplyInWorld(GetOuterWorld());
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionSetOrUnsetInputContext* InputCtx = Cast<UShockActionSetOrUnsetInputContext>(Action))
	{
		InputCtx->ApplyInWorld(GetOuterWorld());
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionChangePressure* Pressure = Cast<UShockActionChangePressure>(Action))
	{
		Pressure->ApplyInWorld(GetOuterWorld());
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionManipulateSpawnZoneRepopulation* SpawnZone = Cast<UShockActionManipulateSpawnZoneRepopulation>(Action))
	{
		SpawnZone->RequestManipulate();
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionSetMovableSpotlightTarget* SpotlightTarget = Cast<UShockActionSetMovableSpotlightTarget>(Action))
	{
		SpotlightTarget->RequestSetTarget();
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionSetMovableSpotlightState* SpotlightState = Cast<UShockActionSetMovableSpotlightState>(Action))
	{
		SpotlightState->RequestSetState();
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionWaitForQuestLogToFinish* QuestLogWait = Cast<UShockActionWaitForQuestLogToFinish>(Action))
	{
		QuestLogWait->RequestWait();
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionToggleAIReactions* ToggleReactions = Cast<UShockActionToggleAIReactions>(Action))
	{
		ToggleReactions->ApplyInWorld(GetOuterWorld());
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionDisplayOnScreenDebugMessage* DebugMsg = Cast<UShockActionDisplayOnScreenDebugMessage>(Action))
	{
		DebugMsg->ApplyInWorld(GetOuterWorld());
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionSetPlayerInvincibility* PlayerInv = Cast<UShockActionSetPlayerInvincibility>(Action))
	{
		PlayerInv->ApplyInWorld(GetOuterWorld());
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionSetAIPatrol* AIPatrol = Cast<UShockActionSetAIPatrol>(Action))
	{
		AIPatrol->ApplyInWorld(GetOuterWorld());
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionChangePawnPhysics* PawnPhysics = Cast<UShockActionChangePawnPhysics>(Action))
	{
		PawnPhysics->ApplyInWorld(GetOuterWorld());
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionSetPawnInvincibility* PawnInv = Cast<UShockActionSetPawnInvincibility>(Action))
	{
		PawnInv->ApplyInWorld(GetOuterWorld());
		++CurrentlyExecutingActionIndex;
		++ActionsCompleted;
		return true;
	}

	if (UShockActionSetAINormalLODOverrideTime* LODOverride = Cast<UShockActionSetAINormalLODOverrideTime>(Action))
	{
		LODOverride->ApplyInWorld(GetOuterWorld());
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
