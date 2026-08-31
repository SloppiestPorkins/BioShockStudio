#pragma once

#include "ShockAction.h"
#include "ShockActionFreezeHavokActor.generated.h"

class AActor;
class UWorld;

/**
 * UnrealScript `ActionFreezeHavokActor`: freeze/unfreeze via UShockPhysicsLibrary.
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

	/** Find TargetLabel actors and ApplyToActor each. */
	virtual bool ApplyInWorld(const FShockActionContext& Ctx) override;
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
