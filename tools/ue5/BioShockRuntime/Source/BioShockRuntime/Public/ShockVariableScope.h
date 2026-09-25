#pragma once

#include "UObject/Object.h"
#include "ShockVariableScope.generated.h"

class UShockScriptRegistry;
class UShockVariable;

/**
 * Scripting.Variable storage for a Script actor, with compatibility string accessors.
 *
 * Names starting with `Global_` (any case) route to a shared store on UShockGameInstance
 * (or a process-level fallback when no game instance exists — headless verify runners).
 * Dotted names `ScriptLabel.varname` resolve as a read of another script's local via the
 * bound registry; assigning a dotted name is refused.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockVariableScope : public UObject
{
	GENERATED_BODY()

public:
	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	bool Contains(FName Name) const;

	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	bool TryGet(FName Name, FString& OutValue) const;

	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	FString GetValueOrEmpty(FName Name) const;

	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	bool Set(FName Name, const FString& Value);

	/** The real Variable object used by Action.resolveInfoList. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	UShockVariable* Find(FName Name) const;

	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	int32 Num() const { return Values.Num(); }

	/** Wire the owning runner's registry so `ScriptLabel.varname` reads can FindScript. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	void BindRegistry(UShockScriptRegistry* InRegistry);

	UFUNCTION(BlueprintPure, Category="BioShock|Script")
	static bool IsGlobalName(FName Name);

	/**
	 * Shared Global_ store: UShockGameInstance when reachable from Context, else a
	 * process-level fallback that never returns null.
	 */
	UFUNCTION(BlueprintCallable, Category="BioShock|Script", meta = (WorldContext = "ContextObject"))
	static UShockVariableScope* GetSharedGlobals(UObject* ContextObject = nullptr);

private:
	UShockVariableScope* ResolveTargetScope(FName Name, FName& OutLocalName, bool bForWrite) const;
	static UShockVariableScope* GetOrCreateFallbackGlobals();

	UPROPERTY()
	TMap<FName, TObjectPtr<UShockVariable>> Values;

	UPROPERTY()
	TWeakObjectPtr<UShockScriptRegistry> BoundRegistry;
};
