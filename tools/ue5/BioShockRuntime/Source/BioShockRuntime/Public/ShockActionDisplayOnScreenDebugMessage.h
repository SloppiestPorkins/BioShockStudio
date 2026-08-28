#pragma once

#include "ShockAction.h"
#include "ShockActionDisplayOnScreenDebugMessage.generated.h"

class UWorld;

/** UnrealScript `ActionDisplayOnScreenDebugMessage`. ApplyInWorld calls AddOnScreenDebugMessage. */
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

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bLastDisplayed = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(const FString& InMessage);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FString GetMessage() const { return Message; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FString GetLastMessage() const { return LastMessage; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetLastDisplayed() const { return bLastDisplayed; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestDisplay();

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
