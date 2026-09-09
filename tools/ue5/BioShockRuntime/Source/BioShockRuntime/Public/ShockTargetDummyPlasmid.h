#pragma once

#include "GameFramework/Actor.h"
#include "ShockPlasmid.h"
#include "ShockTargetDummyPlasmid.generated.h"

class AShockPlayer;
class UStaticMeshComponent;

/**
 * Short-lived decoy placed by Target Dummy. While alive it periodically emits a suspicious-noise
 * event (the same channel splicer hearing already uses, from w13) so nearby AI break off and
 * investigate it.
 */
UCLASS()
class BIOSHOCKRUNTIME_API AShockPlasmidDecoy : public AActor
{
	GENERATED_BODY()

public:
	AShockPlasmidDecoy();

	virtual void Tick(float DeltaSeconds) override;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "BioShock|Plasmid|Decoy")
	TObjectPtr<UStaticMeshComponent> Body;

	/** How far the decoy's lure carries. */
	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "BioShock|Plasmid|Decoy")
	float LureRadius = 1600.0f;

private:
	float PulseAccumulator = 0.0f;
};

/**
 * UnrealScript `DecoyHumanAbility` (Target Dummy). `BioAmmoCost=8`. Spawns a holographic decoy at
 * the aim point that draws splicer aggression for a few seconds. The decoy's holo mesh and the
 * exact aggro transfer are native; `DecoyLifeSeconds` is a PLAUSIBLE stand-in.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockTargetDummyPlasmid : public UShockPlasmid
{
	GENERATED_BODY()

public:
	UShockTargetDummyPlasmid();

	virtual bool Cast(AShockPlayer* Caster, const FHitResult& Aim) override;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "BioShock|Plasmid|TargetDummy")
	float DecoyLifeSeconds = 12.0f;

	UFUNCTION(BlueprintPure, Category = "BioShock|Plasmid|TargetDummy")
	AShockPlasmidDecoy* GetLastDecoyForVerify() const { return LastDecoy.Get(); }

private:
	UPROPERTY(Transient)
	TWeakObjectPtr<AShockPlasmidDecoy> LastDecoy;
};
