#pragma once

#include "ShockAction.h"
#include "ShockActionCreateWatcher.generated.h"

class UShockActionBool;

/**
 * UnrealScript `ActionCreateWatcher`: registers a named watcher on the parent script runner
 * with a boolean statement tree polled once per second (see UShockScriptRunner watchers).
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionCreateWatcher : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionCreateWatcher();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName WatcherName;

	/** Mirrors WatcherBase.enabled (default true). Create only starts polling when true. */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bWatcherEnabled = true;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	TObjectPtr<UShockActionBool> WatchedExpression;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InWatcherName, UShockActionBool* InExpression, bool bInEnabled = true);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void SetWatchedExpression(UShockActionBool* InExpression);

	virtual bool ApplyInWorld(const FShockActionContext& Ctx) override;
};
