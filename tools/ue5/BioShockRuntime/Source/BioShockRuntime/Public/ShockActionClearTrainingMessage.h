#pragma once

#include "ShockAction.h"
#include "ShockActionClearTrainingMessage.generated.h"

/** UnrealScript `ActionClearTrainingMessage`. Records MessageName; no HUD yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionClearTrainingMessage : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionClearTrainingMessage();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName MessageName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastMessageName;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InMessage);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastMessageName() const { return LastMessageName; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestClear();
};
