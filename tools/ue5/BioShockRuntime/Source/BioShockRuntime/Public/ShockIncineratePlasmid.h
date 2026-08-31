#pragma once

#include "ShockPlasmid.h"
#include "ShockIncineratePlasmid.generated.h"

class AShockPawn;
class AShockPlayer;

/**
 * UnrealScript `Incineration` / `IncinerationAbility` slice.
 * EVE cost from IncinerationAbility.uc BioAmmoCost=8; burst/burn are PLAUSIBLE
 * (IncinerationStimuliSet damage is native).
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockIncineratePlasmid : public UShockPlasmid
{
	GENERATED_BODY()

public:
	UShockIncineratePlasmid();

	/** PLAUSIBLE — native stimuli burst, not in decompiled .uc. */
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "BioShock|Plasmid|Incinerate")
	float BurstDamage = 10.0f;

	/** PLAUSIBLE — burn duration from IncinerationStimuliSet stand-in. */
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "BioShock|Plasmid|Incinerate")
	float BurnSeconds = 4.0f;

	/** PLAUSIBLE — damage per second while burning. */
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "BioShock|Plasmid|Incinerate")
	float BurnDps = 6.0f;

	virtual bool Cast(AShockPlayer* Caster, const FHitResult& Aim) override;

	UFUNCTION(BlueprintPure, Category = "BioShock|Plasmid|Incinerate")
	int32 GetLastHitCountForVerify() const { return LastHitCount; }

	UFUNCTION(BlueprintPure, Category = "BioShock|Plasmid|Incinerate")
	bool WasLastCastOnOilForVerify() const { return bLastCastOnOil; }

private:
	void ApplyIncinerateToPawn(AShockPlayer* Caster, AShockPawn* Target);

	UPROPERTY(Transient)
	int32 LastHitCount = 0;

	UPROPERTY(Transient)
	bool bLastCastOnOil = false;
};
