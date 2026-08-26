#pragma once

#include "ShockAction.h"
#include "ShockActionExecuteScript.generated.h"

/**
 * UnrealScript `ActionExecuteScript` (abstract). Looks up a Script by `targetScript` label and
 * starts it, optionally blocking. This slice holds the params and records the request; there is
 * no Script VM yet.
 */
UCLASS(Abstract, BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionExecuteScript : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionExecuteScript();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName TargetScript;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bBlock = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastRequestedScript;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bLastRequestWasBlocking = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InTargetScript, bool bInBlock);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool IsBlocking() const { return bBlock; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastRequestedScript() const { return LastRequestedScript; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool WasLastRequestBlocking() const { return bLastRequestWasBlocking; }

	/** Records the script that would be started. Returns false if TargetScript is None. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestExecute();
};
