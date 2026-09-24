#pragma once

#include "ShockAction.h"
#include "ShockActionExitScript.generated.h"

/**
 * UnrealScript `ActionExitScript`: end execution of TargetScript (a different script, looked up
 * by label via the registry), or the currently-executing script when TargetScript is empty.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionExitScript : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionExitScript();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName TargetScript;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastExitedScript;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InTargetScript);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastExitedScript() const { return LastExitedScript; }

	/** Records exit request. Empty TargetScript means "current script" and still succeeds. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestExit();
};
