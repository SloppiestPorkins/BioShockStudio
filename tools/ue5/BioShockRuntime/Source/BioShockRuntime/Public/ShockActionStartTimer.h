#pragma once

#include "ShockAction.h"
#include "ShockActionStartTimer.generated.h"

/** UnrealScript `ActionStartTimer`. Records Seconds; no script timer yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionStartTimer : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionStartTimer();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float Seconds = 0.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float LastSeconds = 0.0f;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(float InSeconds);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	float GetSeconds() const { return Seconds; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	float GetLastSeconds() const { return LastSeconds; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestStart();
};
