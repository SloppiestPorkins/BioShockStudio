#pragma once

#include "ShockAction.h"
#include "ShockActionFreezeHavokActor.generated.h"

class AActor;

/**
 * UnrealScript `ActionFreezeHavokActor`: freeze/unfreeze a Havok actor.
 * First slice: Freeze=true → disable physics simulation on root body if present; record intent.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionFreezeHavokActor : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionFreezeHavokActor();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName TargetLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bFreeze = true;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bActivateWhenUnfreezing = true;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bLastAppliedFreeze = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InTargetLabel, bool bInFreeze);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetFreeze() const { return bFreeze; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetLastAppliedFreeze() const { return bLastAppliedFreeze; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool ApplyToActor(AActor* Target);
};
