#pragma once

#include "ShockAction.h"
#include "ShockActionDestroyActor.generated.h"

class AActor;
class UWorld;

/**
 * UnrealScript `ActionDestroyActor`: destroy actors labeled `Target`. First slice destroys a
 * passed actor (DestroyActor); label foreach / NotifyKilled still open.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionDestroyActor : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionDestroyActor();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName TargetLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastDestroyedActorName;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InTargetLabel);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetTargetLabel() const { return TargetLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastDestroyedActorName() const { return LastDestroyedActorName; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool DestroyTarget(AActor* Target);

	/** Find actors by TargetLabel and DestroyTarget each. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 DestroyInWorld(UWorld* World);
};
