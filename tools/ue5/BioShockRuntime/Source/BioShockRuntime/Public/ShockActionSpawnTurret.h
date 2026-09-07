#pragma once

#include "ShockAction.h"
#include "ShockActionSpawnTurret.generated.h"

class AActor;
class UWorld;

/**
 * UnrealScript `ActionSpawnTurret`. RequestSpawn records Spawner label.
 * SpawnInWorld finds the labeled spawner marker and spawns a hostile AShockTurret there.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionSpawnTurret : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionSpawnTurret();

	virtual bool ApplyInWorld(const FShockActionContext& Ctx) override;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName SpawnerLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastSpawnerLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	TWeakObjectPtr<AActor> LastSpawnedActor;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InSpawner);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastSpawnerLabel() const { return LastSpawnerLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	AActor* GetLastSpawnedActor() const { return LastSpawnedActor.Get(); }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSpawn();

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	AActor* SpawnAtLocation(UObject* WorldContextObject, FVector Location);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	AActor* SpawnInWorld(UWorld* World);
};
