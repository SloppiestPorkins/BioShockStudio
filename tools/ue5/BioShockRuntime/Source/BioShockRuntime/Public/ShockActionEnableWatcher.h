#pragma once

#include "ShockAction.h"
#include "ShockActionEnableWatcher.generated.h"

/**
 * UnrealScript `ActionEnableWatcher` (extends ActionSetWatcherEnabled with enabled=true).
 * Targets scriptName (or the parent script when None) and sets the named watcher enabled.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionEnableWatcher : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionEnableWatcher();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName ScriptName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName WatcherName;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InScriptName, FName InWatcherName);

	virtual bool ApplyInWorld(const FShockActionContext& Ctx) override;
};
