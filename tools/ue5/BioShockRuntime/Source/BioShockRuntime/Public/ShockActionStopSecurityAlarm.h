#pragma once

#include "ShockAction.h"
#include "ShockActionStopSecurityAlarm.generated.h"

/** UnrealScript `ActionStopSecurityAlarm`. Records stop + dormancy flag; no alarm system yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionStopSecurityAlarm : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionStopSecurityAlarm();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bBotsBecomeDormant = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bLastBotsBecomeDormant = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(bool bInDormant);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetBotsBecomeDormant() const { return bBotsBecomeDormant; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetLastBotsBecomeDormant() const { return bLastBotsBecomeDormant; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestStop();
};
