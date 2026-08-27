#pragma once

#include "UObject/Object.h"
#include "ShockScriptRunner.generated.h"

class UShockAction;
class UShockActionWait;
class UShockVariableScope;

/**
 * First-slice stand-in for UnrealScript `Script` action execution.
 *
 * Holds an authored Actions list, copies it into a run queue on Start, then Tick advances:
 * ActionWait (latent), ActionIf (expand true/else into the queue), variable assigns,
 * ActionExitScript, ActionScriptNote. Unknown actions are stepped over and counted.
 *
 * Not a full VM: no message triggers, no BlockingExecuteScript parent/child, no Loop,
 * no level-placed Script actors yet.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockScriptRunner : public UObject
{
	GENERATED_BODY()

public:
	UShockScriptRunner();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName ScriptLabel;

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

	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	void Configure(FName InLabel);

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

	/** Copies authored Actions into the run queue and begins. Returns false if disabled/empty. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	bool StartExecution();

	/**
	 * Advance until blocked on a Wait or finished. Pass the same monotonic WorldTimeSeconds
	 * a Level would use (editor/test can fake it). Returns true while still executing.
	 */
	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	bool TickExecution(float WorldTimeSeconds);

private:
	UPROPERTY()
	TArray<TObjectPtr<UShockAction>> Actions;

	UPROPERTY()
	TArray<TObjectPtr<UShockAction>> RunQueue;

	UPROPERTY()
	TObjectPtr<UShockActionWait> PendingWait;

	bool bExitRequested = false;
	bool bWaitPrepared = false;

	void FinishExecution();
	bool StepOne(float WorldTimeSeconds);
};
