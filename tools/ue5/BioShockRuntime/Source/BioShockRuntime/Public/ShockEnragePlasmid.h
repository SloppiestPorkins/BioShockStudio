#pragma once

#include "ShockPlasmid.h"
#include "ShockEnragePlasmid.generated.h"

class AShockPlayer;

/**
 * UnrealScript `Enrage` / `EnrageProjectile` slice (hitscan trace — projectile path deferred).
 * EVE cost PLAUSIBLE ~8 (no ability cost in surviving decomp); duration PLAUSIBLE.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockEnragePlasmid : public UShockPlasmid
{
	GENERATED_BODY()

public:
	UShockEnragePlasmid();

	/** PLAUSIBLE — enraged AI targets other AIs, ignores player. */
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "BioShock|Plasmid|Enrage")
	float EnrageDuration = 12.0f;

	virtual bool Cast(AShockPlayer* Caster, const FHitResult& Aim) override;

	UFUNCTION(BlueprintPure, Category = "BioShock|Plasmid|Enrage")
	FName GetLastTargetLabelForVerify() const { return LastTargetLabel; }

private:
	UPROPERTY(Transient)
	FName LastTargetLabel = NAME_None;
};
