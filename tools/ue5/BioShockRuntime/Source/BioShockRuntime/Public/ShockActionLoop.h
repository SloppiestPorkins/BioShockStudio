#pragma once

#include "ShockAction.h"
#include "ShockActionLoop.generated.h"

/**
 * UnrealScript `ActionLoop`: repeatedly run loopActions until ExitLoop.
 * Runner expands LoopActions into the queue and restarts until ExitLoop or 1000 iters.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionLoop : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionLoop();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 CurrentIndex = -1;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bEnteredLoop = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	TArray<TObjectPtr<UShockAction>> LoopActions;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(int32 InCurrentIndex);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void AddLoopAction(UShockAction* Action);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 GetLoopActionNum() const { return LoopActions.Num(); }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 GetCurrentIndex() const { return CurrentIndex; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetEnteredLoop() const { return bEnteredLoop; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestEnterLoop();
};
