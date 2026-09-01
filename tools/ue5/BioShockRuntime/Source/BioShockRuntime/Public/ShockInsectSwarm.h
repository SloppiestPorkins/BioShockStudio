#pragma once

#include "GameFramework/Actor.h"
#include "ShockInsectSwarm.generated.h"

class ABaseShockAI;
class AShockPlayer;

/**
 * Homing insect-swarm effect (InsectSwarmProjectile.uc slice). Not an AI pawn.
 */
UCLASS()
class BIOSHOCKRUNTIME_API AShockInsectSwarm : public AActor
{
	GENERATED_BODY()

public:
	AShockInsectSwarm();

	/** PLAUSIBLE — damage per second while attached. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Plasmid|InsectSwarm")
	float SwarmDps = 4.0f;

	/** PLAUSIBLE — base lifespan (InsectSwarmLifespan_Bonus not in decomp). */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Plasmid|InsectSwarm")
	float LifeSeconds = 6.0f;

	/** PLAUSIBLE — per-tick distract window (swat at swarm, not player). */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Plasmid|InsectSwarm")
	float DistractSeconds = 0.35f;

	void Configure(AShockPlayer* InCaster, ABaseShockAI* InitialVictim);

	UFUNCTION(BlueprintCallable, Category = "BioShock|Plasmid|InsectSwarm")
	void AdvanceForVerify(float DeltaSeconds);

	UFUNCTION(BlueprintPure, Category = "BioShock|Plasmid|InsectSwarm")
	ABaseShockAI* GetCurrentVictimForVerify() const { return CurrentVictim; }

	UFUNCTION(BlueprintPure, Category = "BioShock|Plasmid|InsectSwarm")
	float GetRemainingLifeForVerify() const { return RemainingLife; }

	virtual void Tick(float DeltaSeconds) override;

private:
	void AdvanceSwarm(float DeltaSeconds);
	ABaseShockAI* PickVictim() const;

	UPROPERTY(Transient)
	TObjectPtr<AShockPlayer> Caster;

	UPROPERTY(Transient)
	TObjectPtr<ABaseShockAI> CurrentVictim;

	float RemainingLife = 0.0f;
};
