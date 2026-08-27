#pragma once

#include "ShockAction.h"
#include "ShockActionForceGathererInteractable.generated.h"

/** UnrealScript `ActionForceGathererInteractable`. Records gatherer + flag; no interactable state yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionForceGathererInteractable : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionForceGathererInteractable();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName GathererLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bForceInteractable = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastGathererLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InGatherer, bool bInForceInteractable);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetForceInteractable() const { return bForceInteractable; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastGathererLabel() const { return LastGathererLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestForce();
};
