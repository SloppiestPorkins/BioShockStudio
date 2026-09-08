#pragma once

#include "GameFramework/Actor.h"
#include "ShockEnemySpawner.generated.h"

class ABaseShockAI;
class AShockPlayer;
class AShockTurret;
class UPrimitiveComponent;
class USphereComponent;
class UWorld;

/**
 * Runtime counterpart of BioShock's placed AggressorSpawner.
 *
 * Initial/global entries spawn shortly after BeginPlay. Repopulation entries remain dormant
 * until the player enters the marker radius or a script enables their spawn zone.
 */
UCLASS()
class BIOSHOCKRUNTIME_API AShockAggressorSpawner : public AActor
{
	GENERATED_BODY()

public:
	AShockAggressorSpawner();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Spawning")
	FName SourceKey;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Spawning")
	FName SpawnerLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Spawning")
	TArray<FName> InitialArchetypes;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Spawning")
	TArray<FName> RepopulationArchetypes;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Spawning")
	TArray<FName> SpawnZones;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Spawning")
	FName InitialPatrol;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Spawning")
	FName RepopulationPatrol;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Spawning")
	float ProximityRadius = 1200.0f;

	UFUNCTION(BlueprintCallable, Category="BioShock|Spawning")
	void Configure(
		FName InSourceKey,
		FName InSpawnerLabel,
		const TArray<FName>& InInitialArchetypes,
		const TArray<FName>& InRepopulationArchetypes,
		const TArray<FName>& InSpawnZones,
		FName InInitialPatrol,
		FName InRepopulationPatrol,
		float InProximityRadius);

	UFUNCTION(BlueprintPure, Category="BioShock|Spawning")
	int32 GetResolvedArchetypeCount() const
	{
		return InitialArchetypes.Num() + RepopulationArchetypes.Num();
	}

	UFUNCTION(BlueprintCallable, Category="BioShock|Spawning")
	void SetRepopulationEnabled(bool bEnabled, bool bSpawnNow);

	UFUNCTION(BlueprintCallable, Category="BioShock|Spawning")
	int32 SpawnRepopulation(FName Trigger);

	UFUNCTION(BlueprintCallable, Category="BioShock|Spawning")
	AActor* SpawnForScript(FName Archetype, FName SpawnedLabel);

	bool HasZone(FName Zone) const;
	bool MatchesLabel(FName Label) const;

	/** Shared floor trace + nav projection used by scripted AI and turret actions too. */
	static bool FindGroundedSpawnLocation(
		UWorld* World,
		const FVector& Requested,
		float HeightAboveFloor,
		const AActor* Ignore,
		FVector& OutLocation);

protected:
	virtual void BeginPlay() override;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Spawning")
	TObjectPtr<USphereComponent> ProximityTrigger;

private:
	bool bRepopulationEnabled = true;
	bool bInitialSpawned = false;
	int32 SpawnSerial = 0;
	TArray<TWeakObjectPtr<ABaseShockAI>> LiveInitial;
	TArray<TWeakObjectPtr<ABaseShockAI>> LiveRepopulation;
	FTimerHandle InitialSpawnTimer;
	FTimerHandle InitialRetryTimer;
	FTimerHandle ProximityPollTimer;

	void SpawnInitial();
	void CheckPlayerProximity();
	int32 SpawnArchetypes(
		const TArray<FName>& Archetypes,
		TArray<TWeakObjectPtr<ABaseShockAI>>& Live,
		FName Trigger,
		FName ForcedLabel = NAME_None);
	ABaseShockAI* SpawnOne(FName Archetype, FName Trigger, FName ForcedLabel);
	bool HasLiving(const TArray<TWeakObjectPtr<ABaseShockAI>>& Actors) const;

	UFUNCTION()
	void OnProximityBeginOverlap(
		UPrimitiveComponent* OverlappedComponent,
		AActor* OtherActor,
		UPrimitiveComponent* OtherComponent,
		int32 OtherBodyIndex,
		bool bFromSweep,
		const FHitResult& SweepResult);
};

/** Runtime marker for both immediate and ActionSpawnTurret-driven TurretSpawner records. */
UCLASS()
class BIOSHOCKRUNTIME_API AShockTurretSpawner : public AActor
{
	GENERATED_BODY()

public:
	AShockTurretSpawner();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Spawning")
	FName SourceKey;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Spawning")
	FName SpawnerLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Spawning")
	FName SpawnedTurretLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Spawning")
	FName TurretType;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Spawning")
	TArray<FName> SpawnZones;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Spawning")
	bool bScriptOnly = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Spawning")
	bool bCanBeHacked = true;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Spawning")
	float SightDistance = 1000.0f;

	UFUNCTION(BlueprintCallable, Category="BioShock|Spawning")
	void Configure(
		FName InSourceKey,
		FName InSpawnerLabel,
		FName InSpawnedTurretLabel,
		FName InTurretType,
		const TArray<FName>& InSpawnZones,
		bool bInScriptOnly,
		bool bInCanBeHacked,
		float InSightDistance);

	UFUNCTION(BlueprintCallable, Category="BioShock|Spawning")
	AShockTurret* SpawnTurret(FName Trigger);

	bool MatchesLabel(FName Label) const;

protected:
	virtual void BeginPlay() override;

private:
	TWeakObjectPtr<AShockTurret> SpawnedTurret;
	FTimerHandle InitialSpawnTimer;
	FTimerHandle InitialRetryTimer;
	void SpawnInitialTurret();
};
