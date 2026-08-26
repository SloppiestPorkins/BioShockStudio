#pragma once

#include "ShockAction.h"
#include "ShockActionShowTrainingMessage.generated.h"

/** UnrealScript `ActionShowTrainingMessage`. Records MessageName; no training UI yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionShowTrainingMessage : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionShowTrainingMessage();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName MessageName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastMessageName;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InMessageName);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastMessageName() const { return LastMessageName; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestShow();
};
