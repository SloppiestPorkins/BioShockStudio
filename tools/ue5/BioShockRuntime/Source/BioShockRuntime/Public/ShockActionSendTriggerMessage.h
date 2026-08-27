#pragma once

#include "ShockAction.h"
#include "ShockActionSendTriggerMessage.generated.h"

class UShockScriptRegistry;

/**
 * UnrealScript `ActionSendTriggerMessage`.
 * Dispatches MessageTrigger via UShockScriptRegistry (Instigator as TriggeredBy source;
 * if Instigator is None, uses parent Script label).
 */
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

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 LastDispatchAccepted = 0;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InInstigator);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastInstigatorLabel() const { return LastInstigatorLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 GetLastDispatchAccepted() const { return LastDispatchAccepted; }

	/** Record-only (census / batch8). Prefer DispatchVia when a registry is available. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSend();

	/**
	 * Record + DispatchMessage(MessageTrigger, source).
	 * Source is Instigator, or ParentScriptLabel when Instigator is None (UC fallback).
	 * Returns how many scripts accepted (started or queued).
	 */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 DispatchVia(UShockScriptRegistry* Registry, FName ParentScriptLabel);
};
