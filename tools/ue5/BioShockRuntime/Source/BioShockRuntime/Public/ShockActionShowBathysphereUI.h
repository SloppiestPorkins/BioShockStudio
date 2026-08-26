#pragma once

#include "ShockAction.h"
#include "ShockActionShowBathysphereUI.generated.h"

/** UnrealScript `ActionShowBathysphereUI`. Records BathysphereSystem; no UI yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionShowBathysphereUI : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionShowBathysphereUI();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName BathysphereSystem;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastBathysphereSystem;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InSystem);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastBathysphereSystem() const { return LastBathysphereSystem; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestShow();
};
