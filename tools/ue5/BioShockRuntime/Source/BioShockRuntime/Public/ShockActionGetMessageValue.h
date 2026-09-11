#pragma once

#include "ShockAction.h"
#include "ShockActionGetMessageValue.generated.h"

/**
 * Scripting.ActionGetMessageValue for the message metadata currently retained by the runner.
 * Typed Message UObject fields remain outside the present lightweight message-bus port.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionGetMessageValue : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionGetMessageValue();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName Property;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InPropertyName);

	virtual bool ApplyInWorld(const FShockActionContext& Ctx) override;
};
