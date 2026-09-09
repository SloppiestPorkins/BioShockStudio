#pragma once

#include "Engine/HitResult.h"
#include "UObject/Object.h"
#include "ShockPlasmid.generated.h"

class AShockPlayer;
class AShockPlasmidFx;
class UNiagaraComponent;
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

	/** Exact UAPW_NEWPlayerHands leaf used while this plasmid is equipped. */
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "BioShock|Plasmid|Presentation")
	FName HandIdleAnimation = TEXT("Generic_Fidget");

	/** Exact UAPW_NEWPlayerHands leaf used for the initial cast gesture. */
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "BioShock|Plasmid|Presentation")
	FName HandCastAnimation = TEXT("Generic_Fire");

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "BioShock|Plasmid|Presentation")
	FLinearColor HandTint = FLinearColor(0.35f, 0.6f, 1.0f, 1.0f);

	/** Stand-in Niagara contract authored by author_plasmid_vfx_standins.py. */
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "BioShock|Plasmid|Presentation")
	FString CastFxAssetPath = TEXT("/Game/BioShockFX/Plasmids/NS_GenericCast.NS_GenericCast");

	/** Returns true when the cast attempt completes (EVE may be spent by the caller). */
	UFUNCTION(BlueprintCallable, Category = "BioShock|Plasmid")
	virtual bool Cast(AShockPlayer* Caster, const FHitResult& Aim);

	/** EVE spent this cast (Telekinesis: grab only). Default is EveCost. */
	virtual float GetCastEveCost(const AShockPlayer* Caster) const;

	/** When false, CastActivePlasmid skips cooldown (Telekinesis throw). */
	virtual bool EnforcesCastCooldown(const AShockPlayer* Caster) const;

	/** Map ActionEquipPlasmid Plasmid name → subclass. */
	UFUNCTION(BlueprintPure, Category = "BioShock|Plasmid")
	static TSubclassOf<UShockPlasmid> ResolvePlasmidClass(FName Name);

	/** Last cast presentation component; non-null even when its authored Niagara asset is absent. */
	UFUNCTION(BlueprintPure, Category = "BioShock|Plasmid|Verify")
	UNiagaraComponent* GetLastFxComponentForVerify() const;

protected:
	AShockPlasmidFx* SpawnCastBurst(
		AShockPlayer* Caster,
		const FVector& WorldLocation,
		const FRotator& WorldRotation,
		float LifeSeconds = 0.45f,
		float Radius = 8.0f);

	AShockPlasmidFx* SpawnCastBeam(
		AShockPlayer* Caster,
		const FVector& Start,
		const FVector& End,
		float LifeSeconds = 0.35f,
		float Radius = 2.0f);

	void RememberFx(AShockPlasmidFx* Fx);

private:
	UPROPERTY(Transient)
	TObjectPtr<AShockPlasmidFx> LastFxActor;
};
