#pragma once

#include "UObject/Object.h"
#include "ShockScriptRunner.generated.h"

class UShockAction;
class UShockActionLoop;
class UShockActionFor;
class UShockActionPlayAnimation;
class UShockActionWait;
class UShockActionWaitForGoal;
class UShockActionWaitForQuestLogToFinish;
class UShockScriptRegistry;
class UShockScriptRunner;
class UShockVariableScope;
class UWorld;

/**
 * First-slice stand-in for UnrealScript `Script` action execution.
 *
 * Holds an authored Actions list, copies it into a run queue on Start, then Tick advances:
 * ActionWait, ActionIf, ActionLoop/ExitLoop, ActionFor (counter body repeats),
 * variable assigns, ExitScript, ScriptNote, Blocking/NonBlocking ExecuteScript
 * (child by label), message TriggeredBy start + MessageQueue.
 *
 * Not a full VM: no real Message UObject copies, no level-placed Script actors yet.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockScriptRunner : public UObject
{
	GENERATED_BODY()

public:
	UShockScriptRunner();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName ScriptLabel;

	/**
	 * UnrealScript Actor.TriggeredBy (inherited): comma-separated source labels that may start
	 * this script. Empty does not match (UC only registerMessage when non-empty).
	 */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString TriggeredBy;

	/**
	 * UnrealScript `Script.scriptMessageClass`: which message CLASS from a TriggeredBy source
	 * starts this script -- e.g. two scripts can share TriggeredBy="Lift" but one wants only
	 * MessageMoverOpened and the other only MessageMoverClosing (23-Scripting-Examples.md's
	 * elevator). NAME_None (the default for anything not resolved at import time) and "Message"
	 * (UE2's own base/wildcard class) both match any dispatched class -- see TryStartFromMessage.
	 * docs/research/message-class-gap.md.
	 */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName ScriptMessageClass;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastMessageClass;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString LastMessageSource;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bEnabled = true;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bIsExecuting = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 CurrentlyExecutingActionIndex = -1;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 ActionsCompleted = 0;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	TObjectPtr<UShockVariableScope> Variables;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	TObjectPtr<UShockScriptRegistry> Registry;

	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	void Configure(FName InLabel);

	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	void SetTriggeredBy(const FString& InTriggeredBy);

	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	void SetScriptMessageClass(FName InScriptMessageClass) { ScriptMessageClass = InScriptMessageClass; }

	/** True when a dispatched message class satisfies this script's ScriptMessageClass: an
	 * unresolved/absent class (NAME_None) or UE2's own "Message" wildcard both match anything;
	 * otherwise an exact match is required. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	bool MatchesMessageClass(FName MessageClassName) const;

	/**
	 * UE2 `Script.messageFilter`: a Message instance whose non-empty fields (PawnLabel, PawnClass,
	 * ActualClass, Instigator, Reason ...) an incoming message must equal, compared as text and
	 * case-insensitively like labels. Empty / "None" / "0" fields match anything and are not stored.
	 */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	TMap<FString, FString> MessageFilter;

	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	void SetMessageFilterField(const FString& FieldName, const FString& Value);

	/** True when every filter field the payload can speak to is equal. A field the sender did not
	 * supply is not evidence against the script (senders fill fields incrementally), so it passes. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	bool MatchesMessageFilter(const TMap<FString, FString>& Fields) const;

	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	bool TryStartFromMessageWithFields(
		FName MessageClassName, const FString& SourceLabel, const TMap<FString, FString>& Fields);

	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	FString GetTriggeredBy() const { return TriggeredBy; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	bool MatchesTriggeredBy(const FString& SourceLabel) const;

	/**
	 * If enabled and TriggeredBy matches: start when idle, else enqueue (UC MessageQueue).
	 * Returns true when the message was started or queued; false when rejected.
	 */
	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	bool TryStartFromMessage(FName MessageClassName, const FString& SourceLabel);

	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	FName GetLastMessageClass() const { return LastMessageClass; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	FString GetLastMessageSource() const { return LastMessageSource; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	int32 GetMessageQueueNum() const { return MessageQueue.Num(); }

	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	void SetRegistry(UShockScriptRegistry* InRegistry);

	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	void AddAction(UShockAction* Action);

	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	UShockVariableScope* EnsureVariables();

	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	bool IsExecuting() const { return bIsExecuting; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	int32 GetActionsCompleted() const { return ActionsCompleted; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	int32 GetCurrentIndex() const { return CurrentlyExecutingActionIndex; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	int32 GetRunQueueNum() const { return RunQueue.Num(); }

	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	int32 GetActionCount() const { return Actions.Num(); }

	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	int32 GetLoopDepth() const { return LoopStack.Num(); }

	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	int32 GetForDepth() const { return ForStack.Num(); }

	/** Copies authored Actions into the run queue and begins. Returns false if disabled/empty. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	bool StartExecution();

	/**
	 * Advance until blocked on a Wait / blocking child, or finished.
	 * Also ticks non-blocking children this runner started. Returns true while still executing
	 * (or while a non-blocking child is still running after this runner finished).
	 */
	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	bool TickExecution(float WorldTimeSeconds);

private:
	struct FLoopFrame
	{
		TObjectPtr<UShockActionLoop> Loop;
		int32 BodyStartIndex = 0;
		int32 BodyEndIndex = 0;
		int32 Iteration = 0;
		bool bKeepLooping = true;
	};

	struct FForFrame
	{
		TObjectPtr<UShockActionFor> ForAction;
		int32 BodyStartIndex = 0;
		int32 BodyEndIndex = 0;
		int32 Iteration = 0;
	};

	struct FQueuedMessage
	{
		FName MessageClass;
		FString SourceLabel;
	};

	UPROPERTY()
	TArray<TObjectPtr<UShockAction>> Actions;

	UPROPERTY()
	TArray<TObjectPtr<UShockAction>> RunQueue;

	UPROPERTY()
	TObjectPtr<UShockActionWait> PendingWait;

	UPROPERTY()
	TObjectPtr<UShockActionWaitForGoal> PendingGoalWait;

	UPROPERTY()
	TObjectPtr<UShockActionWaitForQuestLogToFinish> PendingQuestLogWait;

	UPROPERTY()
	TObjectPtr<UShockActionPlayAnimation> PendingAnimation;

	UPROPERTY()
	TObjectPtr<UShockScriptRunner> PendingChild;

	UPROPERTY()
	TArray<TObjectPtr<UShockScriptRunner>> SpawnedChildren;

	TArray<FLoopFrame> LoopStack;
	TArray<FForFrame> ForStack;
	TArray<FQueuedMessage> MessageQueue;

	bool bExitRequested = false;
	bool bWaitPrepared = false;
	bool bGoalWaitPrepared = false;
	bool bQuestLogWaitPrepared = false;

	static constexpr int32 MaxLoopIterations = 1000;

	void FinishExecution();
	bool TryDequeueAndStart();
	bool StepOne(float WorldTimeSeconds);
	bool ResolveLoopBoundaries();
	bool ResolveForBoundaries();
	int32 InsertActionsAt(int32 InsertAt, const TArray<TObjectPtr<UShockAction>>& ToInsert);
	void TickSpawnedChildren(float WorldTimeSeconds);
	bool AnySpawnedChildExecuting() const;
	UWorld* GetOuterWorld() const;
};
