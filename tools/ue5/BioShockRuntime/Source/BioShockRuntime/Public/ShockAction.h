#pragma once

#include "UObject/Object.h"
#include "ShockAction.generated.h"

class AActor;
class UShockAction;
class UShockVariable;
class UShockVariableScope;
class UWorld;

UENUM(BlueprintType)
enum class EShockParameterSourceKind : uint8
{
	Variable,
	ActionProp,
};

/** One serialized `Scripting.Action.ParameterResolveInfo` binding (R1.1). */
USTRUCT(BlueprintType)
struct BIOSHOCKRUNTIME_API FShockParameterResolveInfo
{
	GENERATED_BODY()

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Script")
	FName PropertyName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Script")
	EShockParameterSourceKind SourceKind = EShockParameterSourceKind::Variable;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Script")
	FName VariableName;

	/** Zero-based source export index from the v3 script-actions sidecar. */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Script")
	int32 SourceActionIndex = INDEX_NONE;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Script")
	FName SourcePropertyName = TEXT("Value");

	/** Imported source object; transient result state lives on this same object during a run. */
	UPROPERTY()
	TObjectPtr<UShockAction> SourceAction;
};

/** Per-action execution context built once per UShockScriptRunner::StepOne leaf dispatch. */
struct BIOSHOCKRUNTIME_API FShockActionContext
{
	UWorld* World = nullptr;
	AActor* OwnerActor = nullptr;
	UShockVariableScope* Variables = nullptr;
	AActor* Instigator = nullptr;
	FName SourceLabel;
	FName MessageClass;
	FString MessageSource;
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

	// --- `Scripting.Action.resolveInfoList` / `execute()` return value (R1.1) ---------------
	// A destination property on THIS action binds to either a script-scope Variable (by name)
	// or a sibling/expression action's return Variable.Value (docs/research/script-vm.md).
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Script")
	TArray<FShockParameterResolveInfo> ResolveInfoList;

	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	void AddVariableResolver(FName PropertyName, FName VariableName, FName SourcePropertyName);

	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	void AddActionPropertyResolver(
		FName PropertyName, UShockAction* SourceAction, FName SourcePropertyName, int32 SourceActionIndex);

	/** Apply serialized bindings immediately before execution. False means at least one failed. */
	bool ResolveParameters(const FShockActionContext& Ctx);

	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	UShockVariable* GetReturnValue() const { return ReturnValue; }

	/** Convenience for producer actions; the object is outered to this action. */
	void SetReturnValueText(const FString& Value, FName VariableClassName);

	void ClearReturnValue() { ReturnValue = nullptr; }

	/** false = not implemented / no-op (default for ~115 stubs). */
	virtual bool ApplyInWorld(const FShockActionContext& Ctx) { (void)Ctx; return false; }

private:
	UPROPERTY(Transient)
	TObjectPtr<UShockVariable> ReturnValue;

	bool bResolvingParameters = false;
};
