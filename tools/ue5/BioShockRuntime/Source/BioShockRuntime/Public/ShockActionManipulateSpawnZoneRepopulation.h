#pragma once

#include "ShockAction.h"
#include "ShockActionManipulateSpawnZoneRepopulation.generated.h"

UENUM(BlueprintType)
enum class EShockSpawnZoneRepopulationState : uint8
{
	NoChange = 0,
	Enable = 1,
	Disable = 2,
};

/**
 * UnrealScript `ActionManipulateSpawnZoneRepopulation`. First slice records the request;
 * no SpawningManager yet.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionManipulateSpawnZoneRepopulation : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionManipulateSpawnZoneRepopulation();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName SpawnZoneName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	EShockSpawnZoneRepopulationState AggressorState = EShockSpawnZoneRepopulationState::NoChange;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	EShockSpawnZoneRepopulationState ProtectorState = EShockSpawnZoneRepopulationState::NoChange;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastSpawnZoneName;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InZone, EShockSpawnZoneRepopulationState InAggressor, EShockSpawnZoneRepopulationState InProtector);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastSpawnZoneName() const { return LastSpawnZoneName; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	EShockSpawnZoneRepopulationState GetAggressorState() const { return AggressorState; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestManipulate();
};
