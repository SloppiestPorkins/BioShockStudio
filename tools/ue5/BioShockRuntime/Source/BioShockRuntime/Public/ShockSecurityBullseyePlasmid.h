#pragma once

#include "ShockPlasmid.h"
#include "ShockSecurityBullseyePlasmid.generated.h"

class AShockPlayer;

/**
 * UnrealScript `SecurityBeaconAbility` (Security Bullseye). `BioAmmoCost=5`. Fires a
 * heat-seeking beacon that sticks to the hit AI; every active security bot and camera then
 * treats that AI as its target. Camera-summon and beacon flight are native — this marks the AI
 * and re-commands the placed security bots directly.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockSecurityBullseyePlasmid : public UShockPlasmid
{
	GENERATED_BODY()

public:
	UShockSecurityBullseyePlasmid();

	virtual bool Cast(AShockPlayer* Caster, const FHitResult& Aim) override;

	UFUNCTION(BlueprintPure, Category = "BioShock|Plasmid|Bullseye")
	AActor* GetLastMarkedActorForVerify() const { return LastMarkedActor.Get(); }

	UFUNCTION(BlueprintPure, Category = "BioShock|Plasmid|Bullseye")
	int32 GetLastCommandedBotCountForVerify() const { return LastCommandedBotCount; }

private:
	UPROPERTY(Transient)
	TWeakObjectPtr<AActor> LastMarkedActor;

	UPROPERTY(Transient)
	int32 LastCommandedBotCount = 0;
};
