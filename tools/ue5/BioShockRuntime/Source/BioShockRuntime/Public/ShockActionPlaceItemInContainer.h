#pragma once

#include "ShockAction.h"
#include "ShockActionPlaceItemInContainer.generated.h"

/** UnrealScript `ActionPlaceItemInContainer`. Records ContainerLabel; item source open. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionPlaceItemInContainer : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionPlaceItemInContainer();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName ContainerLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastContainerLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InContainer);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastContainerLabel() const { return LastContainerLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestPlace();
};
