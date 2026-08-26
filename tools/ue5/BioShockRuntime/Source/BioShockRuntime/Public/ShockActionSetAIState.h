#pragma once

#include "ShockAction.h"
#include "ShockActionSetAIState.generated.h"

/** UnrealScript `ActionSetAIState`. AIState kept as shipped ordinal (schema default 2). */
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
};
