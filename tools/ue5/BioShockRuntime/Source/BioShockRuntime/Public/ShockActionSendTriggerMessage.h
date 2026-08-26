#pragma once

#include "ShockAction.h"
#include "ShockActionSendTriggerMessage.generated.h"

/** UnrealScript `ActionSendTriggerMessage`. Records Instigator; no message dispatch yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionSendTriggerMessage : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionSendTriggerMessage();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName InstigatorLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastInstigatorLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InInstigator);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastInstigatorLabel() const { return LastInstigatorLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSend();
};
