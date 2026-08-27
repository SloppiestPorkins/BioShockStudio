#pragma once

#include "ShockAction.h"
#include "ShockActionRagdoll.generated.h"

class UWorld;

/** UnrealScript `ActionRagdoll`. Records AI + impulse; no ragdoll yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionRagdoll : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionRagdoll();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName AILabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bRelativeToAIRotation = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FVector HitImpulseDirection = FVector::ZeroVector;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float HitMomentumImparted = 0.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastAILabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InAI, bool bInRelative, FVector InImpulse, float InMomentum);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastAILabel() const { return LastAILabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetRelativeToAIRotation() const { return bRelativeToAIRotation; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestRagdoll();

	/** Find AILabel actor and apply physics impulse stand-in. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
