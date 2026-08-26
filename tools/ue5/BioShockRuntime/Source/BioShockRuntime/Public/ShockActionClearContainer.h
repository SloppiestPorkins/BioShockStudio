#pragma once

#include "ShockAction.h"
#include "ShockActionClearContainer.generated.h"

/** UnrealScript `ActionClearContainer`. Records ContainerLabel; no inventory yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionClearContainer : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionClearContainer();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName ContainerLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastContainerLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InContainer);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastContainerLabel() const { return LastContainerLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestClear();
};
