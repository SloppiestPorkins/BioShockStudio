#pragma once

#include "GameFramework/Actor.h"
#include "ShockDamageableProp.generated.h"

class UStaticMeshComponent;
class USkeletalMeshComponent;
class UStaticMesh;
class USkeletalMesh;
class AShockPlayer;

/**
 * A world prop that reacts once when damaged (shot/hit) rather than when interacted with --
 * BioShock's `Padlock`, `dyn_grate64`, `NonPhysicalNonPathBlockingReactiveActor`,
 * `OilSlick02_Reactive`/`OilSlick04_Reactive`, and `TV_WallMounted` classes all reduce to this:
 * a mesh that, the first time a weapon hits it, dispatches `MessageRAReacted` with this actor's
 * own label as the source -- the same `AShockPlayer::NotifyReactedWithActor` mechanism
 * `AShockSwitchActor` uses for player-interact triggers. None of these classes had a dedicated
 * actor class wired (`import_level.py`'s "other decoded-but-unplaced classes" fallback), and
 * `UShockDamageLibrary::ApplyDamage` only ever recognized `AShockPawn` targets -- so shooting one
 * of these did nothing at all, not even a graceful no-op, since the non-pawn cast failed and
 * returned 0 before touching Target. Real scripts already gate on these labels (Medical's
 * `OpenSteinmanGate` waits on `GatePadlock`/Reason=Shattered, `KureAllGrate1Damaged` waits on
 * `KureAllGrate1`/Reason=Damaged, `TurnOffLightOnDynamicTelevision` waits on
 * `TV_WallMountedWIthLight`/Reason=Damaged): `UShockScriptRunner::MatchesMessageFilter` only
 * rejects a Want field that is PRESENT with a different value, never one that's simply absent, so
 * the existing Reason-less `NotifyReactedWithActor` dispatch already satisfies these filters
 * without needing to plumb a Reason string through per instance.
 */
UCLASS()
class BIOSHOCKRUNTIME_API AShockDamageableProp : public AActor
{
	GENERATED_BODY()

public:
	AShockDamageableProp();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	TObjectPtr<UStaticMeshComponent> Mesh;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	TObjectPtr<USkeletalMeshComponent> SkeletalMeshComp;

	/** The message-source label scripts' TriggeredBy/RA-filter match against -- the manifest
	 * actor's own label (e.g. "GatePadlock", "KureAllGrate1", "TV_WallMountedWIthLight"). */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="BioShock|DamageableProp")
	FName ReactLabel;

	/** BioShock's grates/padlocks/TVs are single-use triggers in this slice's scope -- default
	 * true so repeated hits after the level has already reacted don't re-dispatch. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|DamageableProp")
	bool bOneShot = true;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|DamageableProp")
	bool bHasReacted = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|DamageableProp")
	void Configure(FName InReactLabel, bool bInOneShot);

	UFUNCTION(BlueprintPure, Category="BioShock|DamageableProp")
	bool CanReact() const { return !bOneShot || !bHasReacted; }

	/** Called from UShockDamageLibrary::ApplyDamage once it resolves the damage instigator to a
	 * player. Dispatches MessageRAReacted via Player->NotifyReactedWithActor(this). Returns false
	 * (no-op, not a failure to report) when bOneShot and already fired. */
	UFUNCTION(BlueprintCallable, Category="BioShock|DamageableProp")
	bool ReactToDamage(AShockPlayer* Player);

	UFUNCTION(BlueprintCallable, Category="BioShock|DamageableProp")
	void SetPropStaticMesh(UStaticMesh* InMesh);

	UFUNCTION(BlueprintCallable, Category="BioShock|DamageableProp")
	void SetPropSkeletalMesh(USkeletalMesh* InMesh);
};
