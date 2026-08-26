#pragma once

#include "ShockAction.h"
#include "ShockActionEndDLCLevel.generated.h"

/** UnrealScript `ActionEndDLCLevel`. Records FailedLevel; no DLC menu yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionEndDLCLevel : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionEndDLCLevel();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bFailedLevel = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bLastFailedLevel = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(bool bInFailed);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetFailedLevel() const { return bFailedLevel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestEnd();
};
