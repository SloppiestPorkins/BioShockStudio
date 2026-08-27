#pragma once

#include "ShockAction.h"
#include "ShockActionSpawnAI.generated.h"

class AActor;
class UWorld;

/**
 * UnrealScript `ActionSpawnAI` (ShockAI.U, native). Calls SpawningManager.SpawnScriptedAI with
 * type, location label, spawned label, radii, mimic/force flags, etc.
 *
 * RequestSpawn records intent. SpawnAtLocation is a playable-slice stand-in that spawns
 * ABaseShockAI in a world — not SpawningManager, archetypes, or loot.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionSpawnAI : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionSpawnAI();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName AITypeToSpawn;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName SpawnLocationLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName SpawnedAILabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float MinRadiusToSpawnAroundSpawnLoc = 0.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float MaxRadiusToSpawnAroundSpawnLoc = 0.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bForceSpawn = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bCorpseCanBeRemoved = true;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastRequestedAIType;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastRequestedLocationLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	TWeakObjectPtr<AActor> LastSpawnedActor;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(
		FName InAIType,
		FName InSpawnLocationLabel,
		FName InSpawnedAILabel,
		float InMinRadius,
		float InMaxRadius,
		bool bInForceSpawn);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetAITypeToSpawn() const { return AITypeToSpawn; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetSpawnLocationLabel() const { return SpawnLocationLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetCorpseCanBeRemoved() const { return bCorpseCanBeRemoved; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastRequestedAIType() const { return LastRequestedAIType; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastRequestedLocationLabel() const { return LastRequestedLocationLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	AActor* GetLastSpawnedActor() const { return LastSpawnedActor.Get(); }

	/** Records the spawn request. Returns false if AITypeToSpawn is None. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSpawn();

	/**
	 * Spawns ABaseShockAI at Location in World. Records RequestSpawn first.
	 * Returns the pawn, or null on failure.
	 */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	AActor* SpawnAtLocation(UObject* WorldContextObject, FVector Location);

	/** Resolve SpawnLocationLabel in World and SpawnAtLocation there. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	AActor* SpawnInWorld(UWorld* World);
};
