#pragma once

#include "ShockAction.h"
#include "ShockActionSetSpawnerRepopulationState.generated.h"

/** UnrealScript `ActionSetSpawnerRepopulationState`. Records SpawnerLabel + Flag. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionSetSpawnerRepopulationState : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionSetSpawnerRepopulationState();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName SpawnerLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bFlag = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastSpawnerLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InSpawner, bool bInFlag);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetFlag() const { return bFlag; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastSpawnerLabel() const { return LastSpawnerLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSet();
};
