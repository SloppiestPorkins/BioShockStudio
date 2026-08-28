#pragma once

#include "ShockAction.h"
#include "ShockActionSetAIState.generated.h"

class UWorld;

/** UnrealScript `ActionSetAIState`. ApplyInWorld stores the ordinal on labeled BaseShockAI. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionSetAIState : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionSetAIState();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 AIState = 2;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName AILabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastAILabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InAILabel, int32 InState);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 GetAIState() const { return AIState; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastAILabel() const { return LastAILabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSet();

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
