#pragma once

#include "ShockPlasmid.h"
#include "ShockElectroBoltPlasmid.generated.h"

class AShockPawn;
class AShockPlayer;

/**
 * UnrealScript `ElectricBolt` / `ElectricBoltAbility` slice.
 * EVE cost from ElectricBoltAbility.uc BioAmmoCost=15; damage/stun/chain are PLAUSIBLE
 * (TraceDamageFactory is native — no authored damage in .uc).
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockElectroBoltPlasmid : public UShockPlasmid
{
	GENERATED_BODY()

public:
	UShockElectroBoltPlasmid();

	/** PLAUSIBLE — TraceDamageFactory damage not in decompiled .uc (BioAmmoCost is EVE, not HP). */
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "BioShock|Plasmid|ElectroBolt")
	float BoltDamage = 15.0f;

	/** PLAUSIBLE — longer than HitStaggerSeconds flinch (~0.35s); original stun via stimuli set. */
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "BioShock|Plasmid|ElectroBolt")
	float StunSeconds = 2.0f;

	/** PLAUSIBLE — water chain radius (subtitle: "Shock them in water to deal damage"). */
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "BioShock|Plasmid|ElectroBolt")
	float WaterChainRadius = 400.0f;

	virtual bool Cast(AShockPlayer* Caster, const FHitResult& Aim) override;

	/**
	 * Shared water-chain for Electro Bolt and electric buck ammo (stun + chain damage in water).
	 * Primary direct hit damage is assumed already applied by the caller.
	 */
	UFUNCTION(BlueprintCallable, Category = "BioShock|Plasmid|ElectroBolt")
	static void ApplyElectricStunAndWaterChain(
		AActor* Instigator,
		AShockPawn* Primary,
		float InStunSeconds,
		float ChainDamage,
		float ChainRadius = 400.0f);

	UFUNCTION(BlueprintPure, Category = "BioShock|Plasmid|ElectroBolt")
	int32 GetLastHitCountForVerify() const { return LastHitCount; }

	UFUNCTION(BlueprintPure, Category = "BioShock|Plasmid|ElectroBolt")
	bool WasLastCastInWaterForVerify() const { return bLastCastInWater; }

private:
	void ApplyBoltToPawn(AShockPlayer* Caster, AShockPawn* Target, float Damage, bool bFromWaterChain);
	void ChainInWater(AShockPlayer* Caster, AShockPawn* Primary, float Damage);

	UPROPERTY(Transient)
	int32 LastHitCount = 0;

	UPROPERTY(Transient)
	bool bLastCastInWater = false;
};
