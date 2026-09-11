#pragma once

#include "UObject/Object.h"
#include "ShockAction.generated.h"

class AActor;
class UShockVariableScope;
class UWorld;

/** Per-action execution context built once per UShockScriptRunner::StepOne leaf dispatch. */
struct BIOSHOCKRUNTIME_API FShockActionContext
{
	UWorld* World = nullptr;
	AActor* OwnerActor = nullptr;
	UShockVariableScope* Variables = nullptr;
	AActor* Instigator = nullptr;
	FName SourceLabel;
};

/**
 * UnrealScript `Action` parameter block. Leaf actions override ApplyInWorld; flow-control
 * actions (Wait / If / Loop / For / variables / ExecuteScript / SendTriggerMessage) stay
 * special-cased in UShockScriptRunner. Adding a new leaf action = override only, no runner edit.
 */
UCLASS()
class BIOSHOCKRUNTIME_API UShockAction : public UObject
{
	GENERATED_BODY()

public:
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString ActionClassName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	TMap<FString, FString> Parameters;

	/** false = not implemented / no-op (default for ~115 stubs). */
	virtual bool ApplyInWorld(const FShockActionContext& Ctx) { (void)Ctx; return false; }

	// --- Minimal `Scripting.Action.execute()` return-value stand-in ------------------------
	// UnrealScript's `execute()` returns a `Variable` that a sibling action's `resolveInfoList`
	// can read as a parameter (R1.1, docs/research/runtime-brain.md §3). This is the smallest
	// possible carrier (a coerced text value) — a producing action (ActionGetProperty,
	// ActionCalcDistance, ActionRandomNumber, ...) calls SetReturnValueText after it runs;
	// the VM's parameter resolver (R1.1) reads it back with GetReturnValueText. Deliberately NOT
	// a typed UShockVariable object yet — keep this the single return-value mechanism so R1.1
	// only has to build the resolver, not a second carrier.
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString ReturnValueText;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bHasReturnValue = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void SetReturnValueText(const FString& InValue) { ReturnValueText = InValue; bHasReturnValue = true; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetReturnValueText(FString& OutValue) const { OutValue = ReturnValueText; return bHasReturnValue; }
};
