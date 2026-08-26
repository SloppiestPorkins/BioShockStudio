#pragma once

#include "ShockAction.h"
#include "ShockActionSpawnPlayerEscortedGatherer.generated.h"

/**
 * UnrealScript `ActionSpawnPlayerEscortedGatherer`.
 * First slice holds vent/spawn labels + flags; no SpawningManager / Little Sister yet.
 * GathererVulnerableState kept as shipped ordinal (schema default 1 on sibling spawners).
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionSpawnPlayerEscortedGatherer : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionSpawnPlayerEscortedGatherer();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName GathererVentLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName SpawnPositionLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName SpawnedGathererLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bCorpseCanBeRemoved = true;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bDontWaitForPlayer = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bForceSpawn = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bShouldPlayerEscort = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 GathererVulnerableState = 1;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastSpawnedGathererLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InVent, FName InPos, FName InSpawned, bool bInForce, bool bInEscort);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastSpawnedGathererLabel() const { return LastSpawnedGathererLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetCorpseCanBeRemoved() const { return bCorpseCanBeRemoved; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSpawn();
};
