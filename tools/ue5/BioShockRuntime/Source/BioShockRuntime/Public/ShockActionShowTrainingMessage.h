#pragma once

#include "ShockAction.h"
#include "ShockActionShowTrainingMessage.generated.h"

class UWorld;

/** UnrealScript `ActionShowTrainingMessage`. ApplyInWorld stores the message on the ShockPlayer. */
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

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
