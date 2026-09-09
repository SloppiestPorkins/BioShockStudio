#pragma once

#include "ShockPlasmid.h"
#include "ShockAirBlastPlasmid.generated.h"

class AShockPlayer;

/**
 * UnrealScript `AirBlastAbility` (Sonic Boom). `BioAmmoCost=15`. The shipped ability applies a
 * `KForce` push through a forward cone and light damage; the exact force curve and damage are
 * native, so `PawnLaunchSpeed` / `BlastDamage` here are PLAUSIBLE stand-ins.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockAirBlastPlasmid : public UShockPlasmid
{
	GENERATED_BODY()

public:
	UShockAirBlastPlasmid();

	virtual bool Cast(AShockPlayer* Caster, const FHitResult& Aim) override;

	/** Cone half-angle cosine — .94 ≈ 20°, matching the ability's tight frontal fan. */
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "BioShock|Plasmid|AirBlast")
	float ConeCosine = 0.94f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "BioShock|Plasmid|AirBlast")
	float BlastRadius = 800.0f;

	/** PLAUSIBLE — horizontal launch speed applied to a caught character. */
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "BioShock|Plasmid|AirBlast")
	float PawnLaunchSpeed = 1400.0f;

	/** PLAUSIBLE — Sonic Boom does chip damage, the knockdown is the point. */
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "BioShock|Plasmid|AirBlast")
	float BlastDamage = 6.0f;

	UFUNCTION(BlueprintPure, Category = "BioShock|Plasmid|AirBlast")
	int32 GetLastAffectedCountForVerify() const { return LastAffectedCount; }

private:
	UPROPERTY(Transient)
	int32 LastAffectedCount = 0;
};
