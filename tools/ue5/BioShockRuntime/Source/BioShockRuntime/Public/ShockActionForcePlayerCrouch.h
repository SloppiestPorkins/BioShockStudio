#pragma once

#include "ShockAction.h"
#include "ShockActionForcePlayerCrouch.generated.h"

class UWorld;

/** UnrealScript `ActionForcePlayerCrouch`. ApplyInWorld calls Crouch/UnCrouch on ShockPlayer. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionForcePlayerCrouch : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionForcePlayerCrouch();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bShouldCrouch = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bLastShouldCrouch = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(bool bInShouldCrouch);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetShouldCrouch() const { return bShouldCrouch; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetLastShouldCrouch() const { return bLastShouldCrouch; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestCrouch();

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
