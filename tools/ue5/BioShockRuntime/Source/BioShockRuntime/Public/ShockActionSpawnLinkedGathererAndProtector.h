#pragma once

#include "ShockAction.h"
#include "ShockActionSpawnLinkedGathererAndProtector.generated.h"

/**
 * UnrealScript `ActionSpawnLinkedGathererAndProtector`.
 * First slice holds labels + corpse/force flags; object refs stored as FName labels.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionSpawnLinkedGathererAndProtector : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionSpawnLinkedGathererAndProtector();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName ProtectorTypeToSpawn;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName AssociatedGathererVentLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName ProtectorLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName GathererLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName ProtectorSpawnLocationLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName GathererSpawnLocationLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bProtectorCorpseCanBeRemoved = true;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bGathererCorpseCanBeRemoved = true;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 GathererVulnerableState = 1;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bForceSpawn = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastGathererLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InProtectorType, FName InVent, FName InProtector, FName InGatherer, bool bInForce);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastGathererLabel() const { return LastGathererLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSpawn();
};
