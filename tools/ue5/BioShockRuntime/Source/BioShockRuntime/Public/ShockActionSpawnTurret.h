#pragma once

#include "ShockAction.h"
#include "ShockActionSpawnTurret.generated.h"

/** UnrealScript `ActionSpawnTurret`. Records Spawner label; no turret spawn yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionSpawnTurret : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionSpawnTurret();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName SpawnerLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastSpawnerLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InSpawner);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastSpawnerLabel() const { return LastSpawnerLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSpawn();
};
