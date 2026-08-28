#pragma once

#include "ShockAction.h"
#include "ShockActionStartSecurityAlarm.generated.h"

class UWorld;

/** UnrealScript `ActionStartSecurityAlarm`. Records alarm request; no bot spawn yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionStartSecurityAlarm : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionStartSecurityAlarm();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName TargetLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName SecurityBotClass;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 NumSecurityBotsToSpawn = 1;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bForceNewSecurityTarget = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bInfiniteAlarm = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastTargetLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InTarget, FName InBotClass, int32 InNumBots, bool bInForce, bool bInInfinite);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 GetNumSecurityBotsToSpawn() const { return NumSecurityBotsToSpawn; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastTargetLabel() const { return LastTargetLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestStart();

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
