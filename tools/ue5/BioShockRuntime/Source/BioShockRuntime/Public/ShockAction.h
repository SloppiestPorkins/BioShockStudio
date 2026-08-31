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
};
