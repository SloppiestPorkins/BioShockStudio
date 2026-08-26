#pragma once

#include "ShockAction.h"
#include "ShockActionApplyImpulse.generated.h"

/** UnrealScript `ActionApplyImpulse` (Scripting.U). Records target + velocity; no physics yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionApplyImpulse : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionApplyImpulse();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName Target;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FVector Velocity = FVector::ZeroVector;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName BoneName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastTarget;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InTarget, FVector InVelocity, FName InBone);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastTarget() const { return LastTarget; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FVector GetVelocity() const { return Velocity; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestApply();
};
