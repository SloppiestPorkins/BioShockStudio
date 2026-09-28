#pragma once

#include "ShockAction.h"
#include "ShockActionDisableWatcher.generated.h"

/**
 * UnrealScript `ActionDisableWatcher` (extends ActionSetWatcherEnabled with enabled=false).
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionDisableWatcher : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionDisableWatcher();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName ScriptName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName WatcherName;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InScriptName, FName InWatcherName);

	virtual bool ApplyInWorld(const FShockActionContext& Ctx) override;
};
