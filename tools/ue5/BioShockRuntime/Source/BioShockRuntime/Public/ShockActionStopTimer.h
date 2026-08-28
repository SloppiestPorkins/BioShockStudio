#pragma once

#include "ShockAction.h"
#include "ShockActionStopTimer.generated.h"

class UWorld;

/** UnrealScript `ActionStopTimer`. Records scriptLabel; no timer clear yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionStopTimer : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionStopTimer();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName ScriptLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastScriptLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InScriptLabel);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastScriptLabel() const { return LastScriptLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestStop();

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
