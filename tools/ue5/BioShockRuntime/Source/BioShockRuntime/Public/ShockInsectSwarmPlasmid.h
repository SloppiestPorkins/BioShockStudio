#pragma once

#include "ShockPlasmid.h"
#include "ShockInsectSwarmPlasmid.generated.h"

class AShockInsectSwarm;
class AShockPlayer;

/**
 * UnrealScript `InsectSwarm` / `InsectSwarmAbility` slice.
 * EVE cost from InsectSwarmAbility.uc BioAmmoCost=8; swarm DPS/lifetime are PLAUSIBLE.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockInsectSwarmPlasmid : public UShockPlasmid
{
	GENERATED_BODY()

public:
	UShockInsectSwarmPlasmid();

	virtual bool Cast(AShockPlayer* Caster, const FHitResult& Aim) override;

	UFUNCTION(BlueprintPure, Category = "BioShock|Plasmid|InsectSwarm")
	AShockInsectSwarm* GetLastSpawnedSwarmForVerify() const { return LastSpawnedSwarm; }

private:
	UPROPERTY(Transient)
	TObjectPtr<AShockInsectSwarm> LastSpawnedSwarm;
};
