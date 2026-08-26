#pragma once

#include "ShockAction.h"
#include "ShockActionWait.generated.h"

/**
 * UnrealScript `ActionWait` (Scripting.U). Latent wait for `Seconds`.
 *
 * Decompiled latentExecute: WakeTime = Level.TimeSeconds + Seconds, then Sleep until
 * TimeSeconds >= WakeTime. This class holds the parameter and the wake check; it does not
 * drive a script VM yet.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionWait : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionWait();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float Seconds = 1.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float WakeAtTime = -1.0f;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void PrepareWait(float WorldTimeSeconds);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool IsReady(float WorldTimeSeconds) const;
};
