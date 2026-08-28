#pragma once

#include "ShockAction.h"
#include "ShockActionTellAIToWait.generated.h"

class UWorld;

/** UnrealScript `ActionTellAIToWait`. ApplyInWorld sets bToldToWait; no Tyrion wait goal. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionTellAIToWait : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionTellAIToWait();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName AILabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastAILabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InAILabel);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastAILabel() const { return LastAILabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestWait();

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
