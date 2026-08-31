#pragma once

#include "ShockPlasmid.h"
#include "ShockTelekinesisPlasmid.generated.h"

class AActor;
class AShockPlayer;

/**
 * UnrealScript `Telekinesis` / `TelekinesisAbility` slice.
 * EVE cost from TelekinesisAbility.uc BioAmmoCost=2.5; grab/throw tuning PLAUSIBLE.
 * Hold stand-in: freeze in place on grab (no per-frame camera follow yet).
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockTelekinesisPlasmid : public UShockPlasmid
{
	GENERATED_BODY()

public:
	UShockTelekinesisPlasmid();

	/** PLAUSIBLE — max trace distance for grab target. */
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "BioShock|Plasmid|Telekinesis")
	float GrabRange = 2500.0f;

	/** PLAUSIBLE — launch speed on throw (vel-change impulse). */
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "BioShock|Plasmid|Telekinesis")
	float ThrowLaunchSpeed = 1500.0f;

	/** PLAUSIBLE — thrown-object hit scan for pawn damage. */
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "BioShock|Plasmid|Telekinesis")
	float ThrowDamage = 15.0f;

	/** PLAUSIBLE — short range pawn hit check along throw direction. */
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "BioShock|Plasmid|Telekinesis")
	float ThrowHitScanRange = 400.0f;

	virtual bool Cast(AShockPlayer* Caster, const FHitResult& Aim) override;

	virtual float GetCastEveCost(const AShockPlayer* Caster) const override;

	virtual bool EnforcesCastCooldown(const AShockPlayer* Caster) const override;

	UFUNCTION(BlueprintPure, Category = "BioShock|Plasmid|Telekinesis")
	FName GetLastActionForVerify() const { return LastAction; }

	UFUNCTION(BlueprintPure, Category = "BioShock|Plasmid|Telekinesis")
	bool DidLastThrowHitForVerify() const { return bLastThrowHit; }

	UFUNCTION(BlueprintPure, Category = "BioShock|Plasmid|Telekinesis")
	AActor* GetHeldActorForVerify() const { return HeldActor; }

private:
	AActor* TraceGrabbable(AShockPlayer* Caster) const;
	FVector ResolveAimDirection(AShockPlayer* Caster, const FHitResult& Aim) const;
	void TryThrowDamage(AShockPlayer* Caster, const FVector& ThrowDir);

	UPROPERTY(Transient)
	TObjectPtr<AActor> HeldActor;

	UPROPERTY(Transient)
	FName LastAction = NAME_None;

	UPROPERTY(Transient)
	bool bLastThrowHit = false;
};
