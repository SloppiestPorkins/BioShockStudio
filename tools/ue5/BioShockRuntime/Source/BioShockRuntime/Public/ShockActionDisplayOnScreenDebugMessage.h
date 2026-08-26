#pragma once

#include "ShockAction.h"
#include "ShockActionDisplayOnScreenDebugMessage.generated.h"

/** UnrealScript `ActionDisplayOnScreenDebugMessage`. Records Message; no ClientMessage yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionDisplayOnScreenDebugMessage : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionDisplayOnScreenDebugMessage();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString Message;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString LastMessage;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(const FString& InMessage);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FString GetMessage() const { return Message; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FString GetLastMessage() const { return LastMessage; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestDisplay();
};
