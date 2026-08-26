#pragma once

#include "ShockAction.h"
#include "ShockActionTellAIToWait.generated.h"

/** UnrealScript `ActionTellAIToWait`. Records AILabel; no Tyrion wait goal yet. */
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
};
