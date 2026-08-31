#pragma once

#include "ShockAction.h"
#include "ShockActionUnlockBathysphereDestination.generated.h"

class UWorld;

/** UnrealScript `ActionUnlockBathysphereDestination`. ApplyInWorld stores unlock on ShockPlayer. */
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

	virtual bool ApplyInWorld(const FShockActionContext& Ctx) override;
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
