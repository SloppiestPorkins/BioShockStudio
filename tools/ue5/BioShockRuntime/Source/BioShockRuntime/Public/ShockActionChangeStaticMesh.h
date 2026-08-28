#pragma once

#include "ShockAction.h"
#include "ShockActionChangeStaticMesh.generated.h"

class UWorld;

/** UnrealScript `ActionChangeStaticMesh`. StaticMesh object stored as FName. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionChangeStaticMesh : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionChangeStaticMesh();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName TargetLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName StaticMeshName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastTargetLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InTarget, FName InMesh);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastTargetLabel() const { return LastTargetLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestChange();

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
