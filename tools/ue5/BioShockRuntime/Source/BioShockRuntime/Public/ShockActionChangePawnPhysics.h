#pragma once

#include "ShockAction.h"
#include "ShockActionChangePawnPhysics.generated.h"

/**
 * UnrealScript `ActionChangePawnPhysics`: enable/disable pawn physics (+ root motion flag).
 * First slice records the request; no Physics mode change yet.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionChangePawnPhysics : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionChangePawnPhysics();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName TargetLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bDisablePhysics = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bEnableRootMotionWhenPhysicsDisabled = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastTargetLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InTarget, bool bInDisable, bool bInRootMotion);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetDisablePhysics() const { return bDisablePhysics; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastTargetLabel() const { return LastTargetLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestChange();
};
