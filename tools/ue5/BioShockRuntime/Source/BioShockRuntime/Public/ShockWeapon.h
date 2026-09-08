#pragma once

#include "GameFramework/Actor.h"
#include "ShockWeaponDef.h"
#include "ShockWeapon.generated.h"

class AShockPawn;
class AShockProjectile;
class UAnimSequence;
class UAudioComponent;
class UPointLightComponent;
class USkeletalMeshComponent;
class UStaticMeshComponent;

/**
 * UnrealScript class `Weapon` (super `Holdable`).
 * Playable-slice stand-in: hitscan FireAt that damages AShockPawn.CurrentHealth.
 * Trace is pawn-object-type only (world static does not eat the shot). Not projectile
 * classes, not TommyGun mesh fire anims.
 */
UCLASS()
class BIOSHOCKRUNTIME_API AShockWeapon : public AActor
{
	GENERATED_BODY()

public:
	AShockWeapon();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	TObjectPtr<USkeletalMeshComponent> Mesh;

	/**
	 * First-person StaticMesh viewmodel (Wrench). Child of Mesh root; hidden until ApplyDef
	 * loads a UStaticMesh. Skeletal Mesh stays the attach root (and must remain non-hidden so
	 * this child can render); "hidden" skeletal viewmodel means no USkeletalMesh assigned.
	 */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	TObjectPtr<UStaticMeshComponent> StaticMesh;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float HitscanDamage = 20.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float HitscanRange = 10000.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 FireCount = 0;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	TWeakObjectPtr<AShockPawn> LastHitPawn;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Ammo")
	int32 MagazineSize = 50;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Ammo")
	int32 RoundsInMagazine = 0;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Ammo")
	int32 ReserveAmmo = 0;

	/** Rounds per second (TommyGun slice ~10). */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Ammo")
	float FireRate = 10.0f;

	/** Hold-to-fire when true (from UShockWeaponDef::bAutomatic). */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Ammo")
	bool bAutomatic = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Ammo")
	float ReloadSeconds = 2.5f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Ammo")
	bool bAutoReload = true;

	/** When false, FireAt skips magazine/reload/rate gates (AI stand-ins). */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Ammo")
	bool bEnforceAmmo = false;

	/** Draw a short-lived debug tracer on each fired round (PIE-visible, no assets). */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Weapon")
	bool bDrawTracers = true;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Ammo")
	bool bIsReloading = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Weapon")
	EWeaponFireMode FireMode = EWeaponFireMode::Hitscan;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Weapon")
	float Spread = 0.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Weapon")
	float MeleeArc = 90.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Weapon")
	float MeleeReach = 180.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Weapon")
	TSubclassOf<AShockProjectile> ProjectileClass;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Weapon")
	int32 PelletCount = 1;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Weapon")
	float PelletSpreadDeg = 0.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Weapon")
	float BeamTickInterval = 0.1f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Weapon")
	float BeamRange = 800.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Weapon")
	EBeamStatus BeamStatus = EBeamStatus::None;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Ammo")
	TArray<FShockAmmoType> AmmoTypes;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Ammo")
	int32 ActiveAmmoTypeIndex = 0;

	UFUNCTION(BlueprintCallable, Category="BioShock|Weapon")
	void ApplyDef(UShockWeaponDef* Def);

	/** Release fire — ends sustained beam (no-op for other fire modes). */
	UFUNCTION(BlueprintCallable, Category="BioShock|Weapon")
	void StopBeam();

	UFUNCTION(BlueprintPure, Category="BioShock|Weapon")
	EWeaponFireMode GetFireMode() const { return FireMode; }

	UFUNCTION(BlueprintPure, Category="BioShock|Weapon")
	bool IsAutomatic() const { return bAutomatic; }

	UFUNCTION(BlueprintPure, Category="BioShock|Weapon")
	bool IsBeamActiveForVerify() const { return bBeamActive; }

	/** Headless verify: override beam status after ApplyDef. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Weapon")
	void SetBeamStatusForVerify(EBeamStatus InStatus) { BeamStatus = InStatus; }

	UFUNCTION(BlueprintPure, Category="BioShock|Weapon")
	FName GetWeaponDefName() const { return DefWeaponName; }

	/**
	 * Headless verify: whether ApplyDef installed a StaticMesh viewmodel (skeletal Mesh hidden).
	 */
	UFUNCTION(BlueprintPure, Category="BioShock|Weapon")
	bool IsStaticViewmodelForVerify() const;

	/**
	 * Headless verify: soft path of the StaticMesh currently on StaticMesh (empty if none).
	 */
	UFUNCTION(BlueprintPure, Category="BioShock|Weapon")
	FSoftObjectPath GetStaticMeshAssetPathForVerify() const;

	UFUNCTION(BlueprintCallable, Category="BioShock|Weapon")
	void ConfigureHitscan(float InDamage, float InRange);

	UFUNCTION(BlueprintCallable, Category="BioShock|Weapon")
	void ConfigureAmmo(int32 InMagazineSize, int32 InReserveAmmo, float InFireRate, float InReloadSeconds);

	/** Full magazine plus reserve pool (slice TommyGun start state). */
	UFUNCTION(BlueprintCallable, Category="BioShock|Weapon")
	void InitializeAmmoFullMag(int32 InReserveAmmo);

	UFUNCTION(BlueprintCallable, Category="BioShock|Weapon")
	int32 GetFireCount() const { return FireCount; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Weapon")
	AShockPawn* GetLastHitPawn() const { return LastHitPawn.Get(); }

	UFUNCTION(BlueprintCallable, Category="BioShock|Ammo")
	int32 GetRoundsInMagazine() const { return RoundsInMagazine; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Ammo")
	int32 GetReserveAmmo() const { return ReserveAmmo; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Ammo")
	int32 GetMagazineSize() const { return MagazineSize; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Ammo")
	bool IsReloading() const { return bIsReloading; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Ammo")
	int32 AddReserveAmmo(int32 Amount);

	/** Advance to next ammo type; swaps active reserve pool (chambered rounds keep current type until mag empties). */
	UFUNCTION(BlueprintCallable, Category="BioShock|Ammo")
	void CycleAmmoType();

	UFUNCTION(BlueprintPure, Category="BioShock|Ammo")
	int32 GetActiveAmmoTypeIndex() const { return ActiveAmmoTypeIndex; }

	UFUNCTION(BlueprintPure, Category="BioShock|Ammo")
	int32 GetAmmoTypeCount() const { return AmmoTypes.Num(); }

	UFUNCTION(BlueprintPure, Category="BioShock|Ammo")
	FName GetActiveAmmoTypeName() const;

	/** Headless verify: jump active ammo index without cycling. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Ammo")
	void SetActiveAmmoTypeIndexForVerify(int32 Index);

	/** Headless verify: override effect on an ammo entry. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Ammo")
	void SetAmmoEffectForVerify(int32 Index, EAmmoEffect Effect);

	UFUNCTION(BlueprintCallable, Category="BioShock|Ammo")
	void SetAmmoStateForVerify(int32 InMag, int32 InReserve);

	UFUNCTION(BlueprintCallable, Category="BioShock|Ammo")
	bool Reload();

	/**
	 * Two-rig viewmodel: play the weapon-side leaf that pairs with the hands clip
	 * (docs/research/viewmodel.md). Missing leaves are a no-op (bind pose / last pose).
	 */
	void PlayIdleMeshAnimation();
	void PlayFireMeshAnimation();
	void PlayEquipMeshAnimation();

	UFUNCTION(BlueprintCallable, Category="BioShock|Ammo")
	void SetAutoReload(bool bEnable) { bAutoReload = bEnable; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Ammo")
	void SetEnforceAmmo(bool bEnable) { bEnforceAmmo = bEnable; }

	/** Headless verify / HUD: set display name without loading a weapon def. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Weapon")
	void SetWeaponDefNameForVerify(FName Name) { DefWeaponName = Name; }

	/** Headless verify: advance reload countdown without real-time wait. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Ammo")
	void AdvanceReloadForVerify(float DeltaSeconds);

	/**
	 * Headless verify: name of the AnimSequence currently installed on this weapon's own Mesh
	 * (not ViewHands). Empty when nothing has been PlayAnimation'd on the weapon rig.
	 */
	UFUNCTION(BlueprintPure, Category="BioShock|Weapon")
	FName GetPlayingMeshAnimationNameForVerify() const;

	/** Headless verify: allow the next shot through the fire-rate gate. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Ammo")
	void ClearFireCooldownForVerify();

	/** Headless verify: advance the fire-rate clock without real-time wait. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Ammo")
	void AdvanceFireRateClockForVerify(float DeltaSeconds);

	UFUNCTION(BlueprintCallable, Category="BioShock|Weapon")
	int32 GetTracerDrawCountForVerify() const { return TracerDrawCount; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Weapon")
	int32 GetMuzzleFlashCountForVerify() const { return MuzzleFlashCount; }

	UFUNCTION(BlueprintPure, Category="BioShock|Audio")
	FName GetFireSoundCueForVerify() const { return FireSoundCue; }

	UFUNCTION(BlueprintPure, Category="BioShock|Audio")
	FName GetReloadSoundCueForVerify() const { return ReloadSoundCue; }

	UFUNCTION(BlueprintPure, Category="BioShock|Audio")
	bool HasSpawnedAudioComponentForVerify() const { return LastAudioComponent != nullptr; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Weapon")
	bool HasMuzzleFlashLightForVerify() const { return MuzzleFlashLight != nullptr; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Weapon")
	bool IsMuzzleFlashLightVisibleForVerify() const;

	/** Headless verify: expire the muzzle-flash timer without real-time wait. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Weapon")
	void AdvanceMuzzleFlashForVerify(float DeltaSeconds);

	/**
	 * Line-trace from Start along Direction. On AShockPawn hit, ApplyAuthoredDamage.
	 * Returns true if a ShockPawn was damaged. Refuses when empty, reloading, or fire-rate gated.
	 */
	UFUNCTION(BlueprintCallable, Category="BioShock|Weapon")
	virtual bool FireAt(AActor* InstigatorActor, FVector Start, FVector Direction);

protected:
	bool CanFireNow(UWorld* World) const;
	float GetMinFireInterval() const;
	double LastFireWorldSeconds = -1.0;

private:
	bool FireAtHitscan(AActor* InstigatorActor, FVector Start, FVector Direction);
	bool FireAtProjectile(AActor* InstigatorActor, FVector Start, FVector Direction);
	bool FireAtMelee(AActor* InstigatorActor, FVector Start, FVector Direction);
	bool FireAtShotgun(AActor* InstigatorActor, FVector Start, FVector Direction);
	bool FireAtBeam(AActor* InstigatorActor, FVector Start, FVector Direction);
	bool CanBeamTickNow(UWorld* World) const;
	void FinishReload();
	void LogAmmoState() const;
	void TryAutoReloadOnEmpty();
	/** Leaf name under /Game/BioShockWeapons/WP_<Def>/Animations/ for this def's reload clip. */
	const TCHAR* ResolveReloadMeshAnimLeaf() const;
	const TCHAR* ResolveIdleMeshAnimLeaf() const;
	const TCHAR* ResolveFireMeshAnimLeaf() const;
	const TCHAR* ResolveEquipMeshAnimLeaf() const;
	UAnimSequence* LoadMeshAnim(const TCHAR* LeafName) const;
	void PlayMeshAnimation(UAnimSequence* Sequence, bool bLoop);
	void PlayReloadMeshAnimation();
	void PlayMeshAnimLeaf(const TCHAR* Leaf, bool bLoop, const TCHAR* PhaseLog);
	bool CanMeleeNow(UWorld* World) const;
	float GetDamageForAmmoIndex(int32 Index) const;
	void SyncActiveAmmoFacingFields();
	void ApplyAmmoHitEffect(AActor* InstigatorActor, AShockPawn* Victim, FVector ImpactPoint, int32 AmmoIndex);
	static FString AmmoEffectToString(EAmmoEffect Effect);
	FVector ResolveMuzzleLocation(const FVector& TraceStart) const;
	void EnsureMuzzleFlashLight();
	void HideMuzzleFlash();
	void FlashMuzzleLight(const FVector& WorldLocation, const FLinearColor& Color, float Intensity, float Duration);
	void PlayDryFireFeedback(const FVector& TraceStart);
	void PlayFireAudio();
	void PlayReloadAudio();
	void PlayMeleeImpactAudio();
	void PlayFireFeedback(
		AActor* InstigatorActor,
		const FVector& MuzzleLocation,
		const FVector& VisualEnd,
		bool bPawnHit,
		bool bWorldHit,
		bool bApplyRecoil = true);

	UPROPERTY(Transient)
	TObjectPtr<UPointLightComponent> MuzzleFlashLight;

	/** Last AnimSequence installed via PlayAnimation on Mesh (weapon rig, not ViewHands). */
	UPROPERTY(Transient)
	TObjectPtr<UAnimSequence> LastMeshAnim;

	UPROPERTY(Transient)
	TObjectPtr<UAudioComponent> LastAudioComponent;

	FTimerHandle ReloadTimerHandle;
	FTimerHandle MuzzleFlashTimerHandle;
	float MuzzleFlashRemaining = 0.0f;
	int32 TracerDrawCount = 0;
	int32 MuzzleFlashCount = 0;
	float ReloadCountdown = 0.0f;
	double LastMeleeWorldSeconds = -1.0;
	float DefProjectileInitialSpeed = 2500.0f;
	float DefProjectileImpactRadius = 0.0f;
	float DefProjectileLifeSeconds = 10.0f;
	FName DefWeaponName;
	FName FireSoundCue;
	FName ReloadSoundCue;
	FName ImpactSoundCue;
	bool bBeamActive = false;
	int32 BeamAmmoTickCounter = 0;
	int32 ChamberedAmmoTypeIndex = 0;
	TArray<int32> AmmoReserves;
	static constexpr int32 BeamAmmoTicksPerRound = 5; // PLAUSIBLE — ~1 round per 0.5s at 0.1s tick
};
