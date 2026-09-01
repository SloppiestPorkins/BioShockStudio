#pragma once

#include "ShockPlasmid.h"
#include "ShockWinterBlastPlasmid.generated.h"

class AShockPlayer;

/**
 * UnrealScript `IcicleAssault` / Winter Blast slice.
 * EVE cost from IcicleAssaultAbility.uc BioAmmoCost=13; cone/freeze/damage are PLAUSIBLE.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockWinterBlastPlasmid : public UShockPlasmid
{
	GENERATED_BODY()

public:
	UShockWinterBlastPlasmid();

	/** PLAUSIBLE — native stimuli set; not in decompiled .uc. */
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "BioShock|Plasmid|WinterBlast")
	float BurstDamage = 5.0f;

	/** PLAUSIBLE — frozen-solid duration. */
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "BioShock|Plasmid|WinterBlast")
	float FreezeSeconds = 4.0f;

	/** PLAUSIBLE — forward cone half-angle (degrees). */
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "BioShock|Plasmid|WinterBlast")
	float ConeHalfAngleDegrees = 22.5f;

	/** PLAUSIBLE — max range from caster (uu). */
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "BioShock|Plasmid|WinterBlast")
	float ConeRadius = 600.0f;

	virtual bool Cast(AShockPlayer* Caster, const FHitResult& Aim) override;

	UFUNCTION(BlueprintPure, Category = "BioShock|Plasmid|WinterBlast")
	int32 GetLastFrozenCountForVerify() const { return LastFrozenCount; }

private:
	UPROPERTY(Transient)
	int32 LastFrozenCount = 0;
};
