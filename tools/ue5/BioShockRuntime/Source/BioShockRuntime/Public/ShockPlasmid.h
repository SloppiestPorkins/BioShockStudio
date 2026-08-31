#pragma once

#include "Engine/HitResult.h"
#include "UObject/Object.h"
#include "ShockPlasmid.generated.h"

class AShockPlayer;
struct FHitResult;

/** BioShock plasmid targeting mode (from ActivePlasmid / ability families). */
UENUM(BlueprintType)
enum class EShockPlasmidTargetingMode : uint8
{
	Instant UMETA(DisplayName = "Instant"),
	Trace UMETA(DisplayName = "Trace"),
	Self UMETA(DisplayName = "Self"),
	AoE UMETA(DisplayName = "AoE"),
};

/**
 * UnrealScript `Plasmid` / `ActivePlasmid` stand-in. Each equipped instance is a UObject owned
 * by the player; subclasses implement Cast().
 */
UCLASS(Abstract, BlueprintType, EditInlineNew, DefaultToInstanced)
class BIOSHOCKRUNTIME_API UShockPlasmid : public UObject
{
	GENERATED_BODY()

public:
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "BioShock|Plasmid")
	FName PlasmidName;

	/** EVE cost per cast. ElectricBoltAbility.uc: BioAmmoCost=15. */
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "BioShock|Plasmid")
	float EveCost = 15.0f;

	/** Seconds between casts. PLAUSIBLE — not in decompiled ElectricBolt*.uc defaults. */
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "BioShock|Plasmid")
	float CastCooldown = 0.5f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "BioShock|Plasmid")
	EShockPlasmidTargetingMode TargetingMode = EShockPlasmidTargetingMode::Trace;

	/** Returns true when the cast attempt completes (EVE may be spent by the caller). */
	UFUNCTION(BlueprintCallable, Category = "BioShock|Plasmid")
	virtual bool Cast(AShockPlayer* Caster, const FHitResult& Aim);

	/** Map ActionEquipPlasmid Plasmid name → subclass. */
	static TSubclassOf<UShockPlasmid> ResolvePlasmidClass(FName Name);
};
