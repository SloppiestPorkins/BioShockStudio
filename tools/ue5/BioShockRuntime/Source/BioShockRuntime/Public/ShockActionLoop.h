#pragma once

#include "ShockAction.h"
#include "ShockActionLoop.generated.h"

/**
 * UnrealScript `ActionLoop`: repeatedly run loopActions until ExitLoop.
 * First slice holds CurrentIndex default -1 and records enter-loop intent; no child VM yet.
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

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(int32 InCurrentIndex);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 GetCurrentIndex() const { return CurrentIndex; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetEnteredLoop() const { return bEnteredLoop; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestEnterLoop();
};
