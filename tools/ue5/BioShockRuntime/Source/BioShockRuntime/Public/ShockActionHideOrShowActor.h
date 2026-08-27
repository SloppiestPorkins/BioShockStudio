#pragma once

#include "ShockAction.h"
#include "ShockActionHideOrShowActor.generated.h"

class AActor;
class UWorld;

/**
 * UnrealScript `ActionHideOrShowActor`: allActorLabel + SetHidden(HideActor).
 * Default HideActor=true (hide). First slice applies to a passed actor; label foreach still open.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionHideOrShowActor : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionHideOrShowActor();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName ActorLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bHideActor = true;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bLastAppliedHide = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bLastApplySucceeded = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InActorLabel, bool bInHideActor);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetHideActor() const { return bHideActor; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetLastAppliedHide() const { return bLastAppliedHide; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool DidLastApplySucceed() const { return bLastApplySucceeded; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool ApplyToActor(AActor* Target);

	/** Find actors by ActorLabel in World and ApplyToActor each. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
