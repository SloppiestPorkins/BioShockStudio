#pragma once

#include "ShockAction.h"
#include "ShockActionUnlockBathysphereDestination.generated.h"

/**
 * UnrealScript `ActionUnlockBathysphereDestination`.
 * Records MapName + BathysphereSystem (default BioshockBathyspheres).
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionUnlockBathysphereDestination : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionUnlockBathysphereDestination();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName MapName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName BathysphereSystem;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastMapName;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InMap, FName InSystem);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastMapName() const { return LastMapName; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestUnlock();
};
