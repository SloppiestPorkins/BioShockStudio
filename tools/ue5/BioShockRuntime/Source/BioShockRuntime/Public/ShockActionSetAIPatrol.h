#pragma once

#include "ShockAction.h"
#include "ShockActionSetAIPatrol.generated.h"

class UWorld;

/** UnrealScript `ActionSetAIPatrol`. ApplyInWorld stores PatrolName on labeled BaseShockAI. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionSetAIPatrol : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionSetAIPatrol();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName AggressorLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName PatrolName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastAggressorLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastPatrolName;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InAggressor, FName InPatrol);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastAggressorLabel() const { return LastAggressorLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastPatrolName() const { return LastPatrolName; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSetPatrol();

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
