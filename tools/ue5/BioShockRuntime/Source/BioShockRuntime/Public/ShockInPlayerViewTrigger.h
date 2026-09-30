#pragma once

#include "GameFramework/Actor.h"
#include "ShockInPlayerViewTrigger.generated.h"

class USceneComponent;

/**
 * BioShock's `InPlayerViewTrigger` class: an invisible point that dispatches a message with its
 * own label once the player looks at it (or, for `bTriggerWhenNotSeen`, once the player looks
 * away after having seen it) -- no mesh, no interact, no damage, just a line-of-sight/FOV
 * condition on the player's own camera. Never had a dedicated actor class wired
 * (`import_level.py`'s "other decoded-but-unplaced classes" fallback), so all 14 instances in
 * 1-Medical imported as inert `TargetPoint`s -- and since these are ALL real `TriggeredBy`
 * targets for real Scripts (`SteinmanIntro`, `Quarantine_PistolIntro`, `Ghost_TwoTwo`,
 * `EternalFlameBlast`, `QuarSwitch_UnlockMaintenanceHall`, `TrainingHackTurret`, ...), none of
 * those scripts could ever fire: several of Medical's scripted narrative/tutorial beats were
 * entirely dead, not degraded.
 *
 * Every one of these Scripts' `scriptMessageClass` resolves to UE2's base `Message` class, which
 * `UShockScriptRunner::MatchesMessageClass` treats as "accept any class from a matching label" --
 * so the exact dispatched message class name doesn't have to match anything specific, only the
 * source label (`TriggeredBy`) does.
 *
 * PLAUSIBLE stand-ins (the original UE2 InPlayerViewTrigger's exact FOV cone and the direction of
 * its `MinimumDistance` gate are not decoded from any available source): a 60-degree half-angle
 * view cone off the player's own camera rotation, `MinimumDistance` read as a maximum range (must
 * be within that many units, not at least that far away), and a plain, unoccluded line trace for
 * line-of-sight.
 */
UCLASS()
class BIOSHOCKRUNTIME_API AShockInPlayerViewTrigger : public AActor
{
	GENERATED_BODY()

public:
	AShockInPlayerViewTrigger();

	/** No mesh, no collision -- but AActor needs a RootComponent for SetActorLocation/spawn-with-
	 * location to actually place it; without one the actor silently stays at (0,0,0). */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	TObjectPtr<USceneComponent> Root;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="BioShock|InPlayerViewTrigger")
	FName TriggerLabel;

	/** Fires on the seen->not-seen edge (after having been seen at least once) instead of the
	 * not-seen->seen edge. Firing immediately just because the trigger was never looked at would
	 * make no narrative sense for pairs like LookAtPresentTrigger/LookAwayFromPresentTrigger. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|InPlayerViewTrigger")
	bool bTriggerWhenNotSeen = false;

	/** 0 = no distance gate. PLAUSIBLE: read as a maximum range, see class comment. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|InPlayerViewTrigger")
	float MinimumDistance = 0.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|InPlayerViewTrigger")
	bool bTriggerEnabled = true;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|InPlayerViewTrigger")
	bool bHasFired = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|InPlayerViewTrigger")
	bool bHasEverBeenSeen = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|InPlayerViewTrigger")
	void Configure(FName InLabel, bool bInTriggerWhenNotSeen, float InMinimumDistance);

	/** True when the player pawn's camera currently has an unoccluded line of sight to this
	 * actor within the FOV cone (and, if set, MinimumDistance). Pure query, no side effects. */
	UFUNCTION(BlueprintPure, Category="BioShock|InPlayerViewTrigger")
	bool IsCurrentlyInPlayerView() const;

	/** Headless verify / manual test hook: runs exactly the Tick evaluation once. Returns true iff
	 * this call caused the trigger to fire. */
	UFUNCTION(BlueprintCallable, Category="BioShock|InPlayerViewTrigger")
	bool EvaluateOnce();

	virtual void Tick(float DeltaSeconds) override;

private:
	void Fire();
};
