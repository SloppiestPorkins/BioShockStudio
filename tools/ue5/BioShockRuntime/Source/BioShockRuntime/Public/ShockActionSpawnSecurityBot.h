#pragma once

#include "ShockAction.h"
#include "ShockActionSpawnSecurityBot.generated.h"

/** UnrealScript `ActionSpawnSecurityBot`. Records spawner + optional pawn handoff. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionSpawnSecurityBot : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionSpawnSecurityBot();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName SpawnerLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bImmediatelyGiveBotToPawn = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName ReceivingPawnLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastSpawnerLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InSpawner, bool bInGive, FName InPawn);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastSpawnerLabel() const { return LastSpawnerLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSpawn();
};
