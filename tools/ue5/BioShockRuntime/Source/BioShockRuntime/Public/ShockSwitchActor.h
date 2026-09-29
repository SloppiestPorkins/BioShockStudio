#pragma once

#include "GameFramework/Actor.h"
#include "ShockSwitchActor.generated.h"

class UStaticMeshComponent;
class USkeletalMeshComponent;
class UStaticMesh;
class USkeletalMesh;
class AShockPlayer;

/**
 * A world lever/switch/button the player interacts with (Press F). BioShock's `DoorSwitch`,
 * `Switch`, `IncineratorSwitch`, `BathysphereSwitch`, `Med_MedicalGateSwitch`, and
 * `ChompersDentalButton` classes all reduce to the same real behaviour: a mesh the player walks up
 * to and presses, which dispatches `MessageRAReacted` with this actor's own label as the message
 * source -- the exact mechanism `AShockPlayer::NotifyReactedWithActor` already implements for
 * `NonPhysicalReactiveActor`. Placed level scripts already gate on these labels via `TriggeredBy`
 * (e.g. Medical's `quarswitch` unlocks the Fisheries quarantine gate) -- before this class existed
 * these actors imported as invisible, non-interactive `TargetPoint` stand-ins (no dedicated actor
 * class was ever wired, `import_level.py`'s "Other decoded-but-unplaced classes" fallback), so
 * every script waiting on one of these labels could never fire from the player's own action.
 */
UCLASS()
class BIOSHOCKRUNTIME_API AShockSwitchActor : public AActor
{
	GENERATED_BODY()

public:
	AShockSwitchActor();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	TObjectPtr<UStaticMeshComponent> Mesh;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	TObjectPtr<USkeletalMeshComponent> SkeletalMeshComp;

	/** The message-source label scripts' TriggeredBy match against -- the manifest actor's own
	 * label (e.g. "quarswitch", "ToNeptuneSwitch"), not necessarily the same as the actor's
	 * editor display label once multiple switches share a class-derived default name. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="BioShock|Switch")
	FName SwitchLabel;

	/** BioShock's own DoorSwitch/etc. classes do not repeat-trigger meaningfully in this slice's
	 * scope (a script runs once and moves state forward); default true so a player mashing F on
	 * an already-used switch does not re-dispatch and re-run a completed script. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Switch")
	bool bOneShot = true;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Switch")
	bool bHasFired = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Switch")
	void Configure(FName InSwitchLabel, bool bInOneShot);

	UFUNCTION(BlueprintPure, Category="BioShock|Switch")
	FString GetInteractionPrompt() const { return TEXT("Press F to use"); }

	UFUNCTION(BlueprintPure, Category="BioShock|Switch")
	bool CanInteract() const { return !bOneShot || !bHasFired; }

	/** Dispatches MessageRAReacted via Player->NotifyReactedWithActor(this). Returns false (no-op,
	 * not a failure to report) when bOneShot and already fired. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Switch")
	bool TryInteract(AShockPlayer* Player);

	UFUNCTION(BlueprintCallable, Category="BioShock|Switch")
	void SetSwitchStaticMesh(UStaticMesh* InMesh);

	UFUNCTION(BlueprintCallable, Category="BioShock|Switch")
	void SetSwitchSkeletalMesh(USkeletalMesh* InMesh);

	/** Headless verify: fire without a real interact trace. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Switch")
	bool InteractForVerify(AShockPlayer* Player) { return TryInteract(Player); }
};
