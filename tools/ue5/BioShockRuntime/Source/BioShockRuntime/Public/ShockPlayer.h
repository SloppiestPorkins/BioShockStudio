#pragma once

#include "ShockPawn.h"
#include "ShockPlayer.generated.h"

class AShockWeapon;
class AShockSecurityDevice;
class UAnimSequence;
class UCameraComponent;
class UInputComponent;
class UShockPlasmid;
class USkeletalMeshComponent;
class UWorld;

DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FOnPlayerDied, AShockPlayer*, Player);

/** UnrealScript `ShockPlayer`. CollisionRadius=34 is on this class's own defaults, not the parent. */
UCLASS()
class BIOSHOCKRUNTIME_API AShockPlayer : public AShockPawn
{
	GENERATED_BODY()

public:
	AShockPlayer();

	virtual void Tick(float DeltaSeconds) override;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	TObjectPtr<AShockWeapon> EquippedWeapon;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Camera")
	TObjectPtr<UCameraComponent> FirstPersonCamera;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Camera")
	TObjectPtr<USkeletalMeshComponent> ViewHands;

	/**
	 * Where the weapon grip sits in camera space: +X forward, +Y right, -Z down. Tunable in the
	 * editor because framing a viewmodel is a look-at-it judgement, not something a headless
	 * verify can settle — lower Z to bring the gun down into frame, raise X to push it away.
	 * Applied by FrameViewmodel on equip.
	 */
	/**
	 * Where the weapon's grip socket sits in camera space: forward, right, up.
	 *
	 * Re-applied every frame (see Tick), so this is an actual screen placement rather than a value
	 * that is only true on the frame the weapon is equipped. Chosen by capture: at the old
	 * (28,10,-24) the grip sat below the frame and the gun's stock was almost touching the eye.
	 * Pushed forward to 68 the whole weapon reads at a sensible size, low and right with the stock
	 * running off the bottom corner, which is where BioShock holds the Tommy gun.
	 *
	 * Override without a rebuild via -bioshockvmoffset=X,Y,Z.
	 */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Camera")
	FVector ViewmodelOffset = FVector(68.0f, 17.0f, -28.0f);

	/**
	 * Viewmodel orientation relative to the camera. Separate from ViewmodelOffset because the first
	 * captured render of the possessed scene showed the arms and weapon INVERTED at the top of
	 * frame - a rotation fault, which no amount of moving the mesh would have fixed.
	 *
	 * Left at identity, which is the state that produces that inverted render, because guessing is
	 * expensive here: one trial is a rebuild plus a ~10 minute capture, and roll 180 (the obvious
	 * first guess) pushed the mesh out of frame entirely rather than righting it. Pitch 180 and yaw
	 * 180 are the untried candidates. In the editor this is a five-second drag with live feedback,
	 * which is the right loop for it.
	 */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Camera")
	FRotator ViewmodelRotation = FRotator::ZeroRotator;

	/**
	 * When true, SetupPlayerInputComponent binds Fire + Move/Look axes.
	 * Defaults true so GameMode-spawned PIE pawns walk/fire without an extra script call.
	 */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bPlayableInputEnabled = true;

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void EquipWeapon(AShockWeapon* Weapon);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	AShockWeapon* GetEquippedWeapon() const { return EquippedWeapon; }

	/** BioShock holster order: Wrench, Pistol, Machine Gun, Shotgun, GL, Chem Thrower, Crossbow, Camera. */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Weapon")
	TArray<TObjectPtr<AShockWeapon>> WeaponSlots;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Weapon")
	int32 ActiveWeaponSlot = -1;

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	AShockWeapon* GiveWeaponByDef(FName DefName, int32 Slot);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	AShockWeapon* GiveWeapon(TSubclassOf<AShockWeapon> WeaponClass, int32 Slot);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	bool SelectWeaponSlot(int32 Slot);

	/** Activate an already-equipped plasmid slot (radial / select screen). */
	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	bool SelectPlasmidSlot(int32 Slot);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void NextWeapon();

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void PrevWeapon();

	UFUNCTION(BlueprintPure, Category="BioShock|Player")
	AShockWeapon* GetWeaponInSlot(int32 Slot) const;

	UFUNCTION(BlueprintPure, Category="BioShock|Player")
	int32 GetActiveWeaponSlot() const { return ActiveWeaponSlot; }

	/** Headless verify: IsHidden() on the weapon actor in a holster slot. */
	UFUNCTION(BlueprintPure, Category="BioShock|Player")
	bool IsWeaponSlotHidden(int32 Slot) const;

	/**
	 * Playable-slice helpers. AutoPossess stays Disabled (GameMode + PlayerStart spawn path).
	 * Needs project ActionMapping "Fire" and AxisMappings MoveForward/MoveRight/Turn/LookUp.
	 */
	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void EnablePlayableInput(bool bEnable);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	bool IsPlayableInputEnabled() const { return bPlayableInputEnabled; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	bool TryFireEquippedWeapon();

	/**
	 * Headless verify: drive Fire the same path ActionMapping "Fire" uses (press/release),
	 * so automatic weapons can be tested without a real input device.
	 */
	UFUNCTION(BlueprintCallable, Category="BioShock|Player|Verify")
	void DriveFireInputForVerify(bool bPressed);

	/**
	 * Headless verify: drive WeaponSlotN the same path ActionMapping "WeaponSlotN" uses
	 * (1=Wrench … 5=GrenadeLauncher … 7=Crossbow). Not a direct SelectWeaponSlot call.
	 */
	UFUNCTION(BlueprintCallable, Category="BioShock|Player|Verify")
	void DriveWeaponSlotInputForVerify(int32 SlotOneBased);

	/** Headless verify: whether Fire is currently held (after DriveFireInputForVerify / bindings). */
	UFUNCTION(BlueprintPure, Category="BioShock|Player|Verify")
	bool IsFireInputHeldForVerify() const { return bFireInputHeld; }

	/**
	 * Headless verify: advance the fire-rate clock and re-trigger automatic fire while held,
	 * without waiting on real time. Mirrors Tick's held-fire path.
	 */
	UFUNCTION(BlueprintCallable, Category="BioShock|Player|Verify")
	void AdvanceHeldFireForVerify(float DeltaSeconds);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	bool TryReloadEquippedWeapon();

	/** BioShock EVE pool (playable-slice stand-in; ~100 default). */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Player")
	float CurrentEve = 100.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Player")
	float MaxEve = 100.0f;

	/** PLAUSIBLE — EVE hypo refill amount; consumed via UseEveHypo / inventory stack. */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Player")
	float EveHypoAmount = 50.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Player")
	bool bInfiniteEve = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	bool ConsumeEve(float Amount);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void RefillEve(float Amount);

	UFUNCTION(BlueprintPure, Category="BioShock|Player")
	float GetCurrentEve() const { return CurrentEve; }

	UFUNCTION(BlueprintPure, Category="BioShock|Player")
	float GetMaxEve() const { return MaxEve; }

	/** Three plasmid slots (UnrealScript ActivePlasmid array). */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Player")
	TArray<TObjectPtr<UShockPlasmid>> EquippedPlasmids;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Player")
	int32 ActivePlasmidSlot = 0;

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	bool EquipPlasmid(TSubclassOf<UShockPlasmid> PlasmidClass, int32 Slot);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void ClearAllPlasmids();

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	UShockPlasmid* GetActivePlasmid() const;

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	bool CastActivePlasmid();

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void CycleActivePlasmid();

	UFUNCTION(BlueprintPure, Category="BioShock|Player")
	float GetPlasmidCooldownRemaining() const;

	/** Headless verify: force EVE to zero. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void SetCurrentEveForVerify(float Value) { CurrentEve = FMath::Clamp(Value, 0.0f, MaxEve); }

	/**
	 * UnrealScript `ShockPlayer.AddStackToInventory` stand-in: merge StackSize into the
	 * named ItemClass. FirstAidKit / EveHypo stacks clamp to MaxFirstAidKits / MaxEveHypos.
	 * Returns the new stack total, or 0 if the grant is refused.
	 */
	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	int32 AddStackToInventory(FName ItemClass, int32 StackSize);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	int32 RemoveStackFromInventory(FName ItemClass, int32 StackSize);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	int32 GetInventoryStack(FName ItemClass) const;

	/** PLAUSIBLE carry cap — BioShock U-Invent max ~9 per consumable type. */
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category="BioShock|Player|Consumables")
	int32 MaxFirstAidKits = 9;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category="BioShock|Player|Consumables")
	int32 MaxEveHypos = 9;

	/** PLAUSIBLE — first-aid kit heal chunk; UC kit restores a large fraction, not always full. */
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category="BioShock|Player|Consumables")
	float FirstAidHealAmount = 60.0f;

	/** Off by default so slice / possess verifies stay unchanged. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Player|Consumables")
	bool bAutoFirstAid = false;

	/** PLAUSIBLE — auto-use kit when health drops below this fraction of max. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Player|Consumables")
	float AutoFirstAidThreshold = 0.35f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Player|Consumables")
	int32 PlayerMoney = 0;

	/** ADAM currency (Gatherer's Garden). Separate from money; U4 pause strip binds GetAdam. */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Player|Consumables")
	int32 PlayerAdam = 0;

	UFUNCTION(BlueprintCallable, Category="BioShock|Player|Consumables")
	void Heal(float Amount);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player|Consumables")
	bool UseFirstAidKit();

	UFUNCTION(BlueprintCallable, Category="BioShock|Player|Consumables")
	bool UseEveHypo();

	UFUNCTION(BlueprintCallable, Category="BioShock|Player|Consumables")
	void AddMoney(int32 Amount);

	UFUNCTION(BlueprintPure, Category="BioShock|Player|Consumables")
	int32 GetMoney() const { return PlayerMoney; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Player|Consumables")
	void AddAdam(int32 Amount);

	UFUNCTION(BlueprintPure, Category="BioShock|Player|Consumables")
	int32 GetAdam() const { return PlayerAdam; }

	UFUNCTION(BlueprintPure, Category="BioShock|Player|Consumables")
	float GetMaxHealth() const;

	/** Headless verify: set health without going through damage. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Player|Consumables")
	void SetCurrentHealthForVerify(float Value);

	/** Called from damage library when bAutoFirstAid is enabled. */
	void TryAutoFirstAidAfterDamage();

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void SetForcedCrouch(bool bShouldCrouch);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	bool IsForcedCrouch() const { return bForcedCrouch; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void SetMovementDisabled(bool bDisable);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	bool IsMovementDisabled() const { return bMovementDisabled; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void SetConceptEnabled(FName ConceptName, bool bEnable);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	bool IsConceptEnabled(FName ConceptName) const;

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void SetTipPriority(FName TipName, int32 Priority);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	int32 GetTipPriority(FName TipName) const;

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void SetScriptedSequenceRunNow(FName SequenceLabel, int32 RunNow);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	int32 GetScriptedSequenceRunNow(FName SequenceLabel) const;

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void SetInputContext(FName Context, bool bUnset);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	FName GetCurrentInputContext() const { return CurrentInputContext; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	FName GetLastInputContext() const { return LastInputContext; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void SetRegionPressure(FName RegionName, uint8 Pressure);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	uint8 GetRegionPressure(FName RegionName) const;

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void AssertFact(FName Slot1, const FString& Slot2, const FString& Slot3);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void RetractFact(FName Slot1, const FString& Slot2, const FString& Slot3);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	bool HasFact(FName Slot1, const FString& Slot2, const FString& Slot3) const;

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void InitiateQuest(FName QuestName, bool bSetActive);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void CompleteQuestObjective(FName QuestName, int32 Count);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void CompleteQuest(FName QuestName);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void FailQuest(FName QuestName);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	int32 GetQuestState(FName QuestName) const;

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	int32 GetQuestObjectiveCount(FName QuestName) const;

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	FName GetActiveQuest() const { return ActiveQuest; }

	/** Quests currently in state 1 (initiated / active). Used by the status Goals tab. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void GetActiveQuestNames(TArray<FName>& OutNames) const;

	UFUNCTION(BlueprintPure, Category="BioShock|Player")
	int32 GetActiveQuestCount() const;

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void SetQuestHint(FName QuestName, FName HintName);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	FName GetQuestHint(FName QuestName) const;

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void SetAutoSaveCommand(const FString& Command);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	FString GetAutoSaveCommand() const { return LastAutoSaveCommand; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void SetPendingTimerSeconds(float Seconds);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	float GetPendingTimerSeconds() const { return PendingTimerSeconds; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void StopTimerForScript(FName ScriptLabel);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	FName GetStoppedTimerLabel() const { return StoppedTimerLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void SetMapHUDRegion(const FString& Description);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	FString GetMapHUDRegion() const { return LastMapHUDRegion; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void SetTrainingMessage(FName MessageName);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	FName GetTrainingMessage() const { return LastTrainingMessage; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void SetFadeVolumeOverride(float Volume, float Duration);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	float GetFadeVolumeOverride() const { return FadeVolumeOverride; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	float GetFadeVolumeDuration() const { return FadeVolumeDuration; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void SetLevelSavingDisabled(bool bDisable);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	bool IsLevelSavingDisabled() const { return bLevelSavingDisabled; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void SetLevelSwitchingDisabled(bool bDisable);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	bool IsLevelSwitchingDisabled() const { return bLevelSwitchingDisabled; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void SetHUDEnabled(bool bEnable);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	bool IsHUDEnabled() const { return bHUDEnabled; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void SetResurrectionStationActivated(FName Station, bool bActivated);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	bool IsResurrectionStationActivated(FName Station) const;

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void SetResurrectionStationEnabled(FName Station, bool bEnabled);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	bool IsResurrectionStationEnabled(FName Station) const;

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void UnlockBathysphereDestination(FName System, FName MapName);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	bool IsBathysphereDestinationUnlocked(FName System, FName MapName) const;

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void RemoveAvailableHoldable(FName HoldableClass);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	bool IsHoldableRemoved(FName HoldableClass) const;

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void SetClientMessage(const FString& Text);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	FString GetClientMessage() const { return LastClientMessage; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void SetHUDPlaying(bool bPlaying);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	bool IsHUDPlaying() const { return bHUDPlaying; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void SetSecurityAlarmOn(bool bOn, FName TargetLabel);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	bool IsSecurityAlarmOn() const { return bSecurityAlarmOn; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	FName GetLastAlarmTarget() const { return LastAlarmTarget; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void SetSpawnZoneRepopulation(FName Zone, uint8 Aggressor, uint8 Protector);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	uint8 GetSpawnZoneAggressor(FName Zone) const;

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void SetSpotlightTarget(FName Spotlight, FName Target);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	FName GetSpotlightTarget(FName Spotlight) const;

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void SetSpotlightOn(FName Spotlight, bool bOn);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	bool IsSpotlightOn(FName Spotlight) const;

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void SetQuestLogWait(FName QuestLogClass);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	FName GetLastQuestLogWait() const { return LastQuestLogWait; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void SetMaterialSwitchIndex(FName MaterialSwitch, float Index);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	float GetMaterialSwitchIndex(FName MaterialSwitch) const;

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void SetSecurityHacked(bool bHacked, float ShutdownTime);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	bool IsSecurityHacked() const { return bSecurityHacked; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	float GetSecurityHackShutdownTime() const { return SecurityHackShutdownTime; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void SetTurretHacked(FName Turret, bool bHacked);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	bool IsTurretHacked(FName Turret) const;

	/** Deterministic skill-check stand-in: succeeds when Difficulty01 <= HackSkill. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Player|Hacking")
	bool TryHackDevice(AShockSecurityDevice* Device, float Difficulty01);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player|Hacking")
	bool UnHackDevice(AShockSecurityDevice* Device);

	/** Default 0.7 — verify can override via SetHackSkillForVerify. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Player|Hacking")
	float HackSkill = 0.7f;

	UFUNCTION(BlueprintCallable, Category="BioShock|Player|Hacking")
	void SetHackSkillForVerify(float Skill) { HackSkill = Skill; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void SetDoorBroken(FName Door, bool bBroken);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	bool IsDoorBroken(FName Door) const;

	/** Possessed ShockPlayer, or the first placed one (editor/headless). */
	static AShockPlayer* FindLocalOrFirst(UWorld* World);

	/** Fired once when ApplyDamage flips bIsDead true. */
	UPROPERTY(BlueprintAssignable, Category="BioShock|Player")
	FOnPlayerDied OnPlayerDied;

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void OnDied();

	UFUNCTION(BlueprintPure, Category="BioShock|Player")
	int32 GetDeathNotifyCount() const { return DeathNotifyCount; }

	/** Subtle camera kick when the equipped weapon fires (presentation only). */
	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void ApplyWeaponRecoil();

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	float GetWeaponRecoilKickRemainingForVerify() const { return WeaponRecoilKickRemaining; }

	/** Headless verify: spawn a default controller so ApplyWeaponRecoil can touch ControlRotation. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void EnsureControllerForVerify();

	/** Raw GetControlRotation().Pitch (may be wrapped outside [-90, 90]). */
	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	float GetControlRotationPitchForVerify() const;

	/** Set ControlRotation.Pitch without normalizing — used to reproduce wrapped-pitch recoil. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void SetControlRotationPitchForVerify(float PitchDegrees);

	/** Headless verify: ease recoil back without real-time wait. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void AdvanceWeaponRecoilForVerify(float DeltaSeconds);

	/** Grip socket currently used by FrameViewmodel / AttachToComponent (NAME_None = no correction). */
	UFUNCTION(BlueprintPure, Category="BioShock|Player|ViewHands")
	FName GetActiveGripSocketForVerify() const { return ActiveGripSocket; }

	/** World location of the active grip socket (ZeroVector if unresolved). */
	UFUNCTION(BlueprintPure, Category="BioShock|Player|ViewHands")
	FVector GetActiveGripSocketWorldLocationForVerify() const;

	/** Equipped weapon mesh Bounds.Origin in world space (ZeroVector if no mesh). */
	UFUNCTION(BlueprintPure, Category="BioShock|Player|ViewHands")
	FVector GetEquippedWeaponBoundsCenterForVerify() const;

	/** Equipped weapon skeletal root bone (index 0) in world space. */
	UFUNCTION(BlueprintPure, Category="BioShock|Player|ViewHands")
	FVector GetEquippedWeaponRootBoneWorldLocationForVerify() const;

	/**
	 * Distance from grip socket to weapon root bone after EquipWeapon alignment.
	 * Should be near zero — context.md: weapon root bone IS the hands' socket.
	 */
	UFUNCTION(BlueprintPure, Category="BioShock|Player|ViewHands")
	float GetGripToWeaponRootDistanceForVerify() const;

	/**
	 * Camera-space lateral (|Y|) offset of weapon bounds center from the grip socket.
	 * A forward-pointing gun has most extent on +X; a large |Y| vs |X| is a gross sideways misalign.
	 */
	UFUNCTION(BlueprintPure, Category="BioShock|Player|ViewHands")
	float GetGripToWeaponBoundsLateralDistanceForVerify() const;

	/**
	 * Headless verify: how many USkeletalMeshComponents the equipped weapon owns.
	 * TommyGun's ammo drum (TG_AmmoClip) is a bone on the same mesh — count must stay 1
	 * after AlignEquippedWeaponRootToGripSocket (no orphan secondary component).
	 */
	UFUNCTION(BlueprintPure, Category="BioShock|Player|ViewHands")
	int32 GetEquippedWeaponSkeletalMeshComponentCountForVerify() const;

	/** Headless verify: whether the equipped weapon skeleton has the named bone. */
	UFUNCTION(BlueprintPure, Category="BioShock|Player|ViewHands")
	bool DoesEquippedWeaponBoneExistForVerify(FName BoneName) const;

	/**
	 * Headless verify: world distance between two bones on the equipped weapon mesh.
	 * Returns -1 when either bone is missing. Used to assert TG_AmmoClip stays with
	 * TG_TommyGunBody after root-bone grip align (same-skeleton, not a detachable actor).
	 */
	UFUNCTION(BlueprintPure, Category="BioShock|Player|ViewHands")
	float GetEquippedWeaponBoneDistanceForVerify(FName BoneA, FName BoneB) const;

	/** Headless verify: name of the AnimSequence currently installed on ViewHands. */
	UFUNCTION(BlueprintPure, Category="BioShock|Player|ViewHands")
	FName GetPlayingViewHandsAnimationNameForVerify() const;

	/** Headless verify: ReloadPistol / FastReloadPistol play length (0 if unresolved). */
	UFUNCTION(BlueprintPure, Category="BioShock|Player|ViewHands")
	float GetViewHandsReloadPlayLengthForVerify() const;

	/**
	 * Headless verify: drive MoveForward the same path AxisMapping "MoveForward" uses
	 * (Controller yaw + AddMovementInput), not a lower-level movement call.
	 */
	UFUNCTION(BlueprintCallable, Category="BioShock|Player|Verify")
	void DriveMoveForwardForVerify(float Value) { MoveForward(Value); }

	/**
	 * Headless verify: advance the ViewHands one-shot timer (equip/fire/reload → fidget) without
	 * waiting on real time. Mirrors ABaseShockAI combat anim one-shot handling.
	 */
	UFUNCTION(BlueprintCallable, Category="BioShock|Player|ViewHands")
	void AdvanceViewHandsAnimationForVerify(float DeltaSeconds);

	/** Called from AShockWeapon fire feedback when a discrete shot applies recoil. */
	void NotifyViewHandsWeaponFired();

	/** Called from AShockWeapon::Reload when a reload actually starts. */
	void NotifyViewHandsWeaponReloadStarted();

	/** Per-archetype research from the Research Camera (key = BaseShockAI::AITypeName). */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Research")
	TMap<FName, float> ResearchPointsByArchetype;

	/** PLAUSIBLE slice thresholds — UC uses per-track ScoreRequired (e.g. 25/300/600/1000/1750). */
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category="BioShock|Research")
	TArray<float> ResearchLevelThresholds = {0.0f, 100.0f, 300.0f, 700.0f, 1500.0f};

	/** PLAUSIBLE — +10% weapon damage per research level vs that archetype. */
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category="BioShock|Research")
	float ResearchDamageBonusPerLevel = 0.10f;

	UFUNCTION(BlueprintCallable, Category="BioShock|Research")
	void AddResearchPoints(FName Archetype, float Points);

	UFUNCTION(BlueprintPure, Category="BioShock|Research")
	int32 GetResearchLevel(FName Archetype) const;

	UFUNCTION(BlueprintPure, Category="BioShock|Research")
	float GetResearchDamageMultiplier(FName Archetype) const;

	UFUNCTION(BlueprintPure, Category="BioShock|Research")
	float GetResearchPointsForVerify(FName Archetype) const;

	/** Level-travel: copy inventory stacks without exposing the private map. */
	TMap<FName, int32> GetInventoryStacksForTravel() const;

	/** Level-travel: replace inventory stacks from a captured blob. */
	void RestoreInventoryStacksForTravel(const TMap<FName, int32>& Stacks);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void ResetForRespawn(float Health);

	virtual void OnDeathFromDamage() override;
	virtual void PossessedBy(AController* NewController) override;
	virtual void SetupPlayerInputComponent(UInputComponent* PlayerInputComponent) override;

private:
	void HandleFireInput();
	void HandleFireReleasedInput();
	void HandleReloadInput();
	void HandleAmmoCycleInput();
	void HandlePlasmidInput();
	void HandlePlasmidReleasedInput();
	void HandlePlasmidCastInput();
	void HandlePlasmidCycleInput();
	void HandleWeaponRadialPressed();
	void HandleWeaponRadialReleased();
	void HandleWeaponSelectToggle();
	void HandleWeaponNextInput();
	void HandleWeaponPrevInput();
	void HandleWeaponSlot1Input();
	void HandleWeaponSlot2Input();
	void HandleWeaponSlot3Input();
	void HandleWeaponSlot4Input();
	void HandleWeaponSlot5Input();
	void HandleWeaponSlot6Input();
	void HandleWeaponSlot7Input();
	void HandleRadialStepLeft();
	void HandleRadialStepRight();
	void HandleStatusMenuToggle();
	void HandlePauseMenuToggle();
	void UpdateWeaponSlotVisibility(int32 VisibleSlot);
	bool PerformPlasmidAimTrace(FHitResult& OutHit) const;
	void HandleHackToolInput();
	void HandleUseFirstAidInput();
	void HandleUseEveHypoInput();
	bool PerformHackToolTrace(AShockSecurityDevice*& OutDevice) const;
	void MoveForward(float Value);
	void MoveRight(float Value);
	void TurnAtRate(float Value);
	void LookUpAtRate(float Value);
	void EnsureViewHands();
	void FrameViewmodel(FName GripSocket);
	void AlignEquippedWeaponRootToGripSocket();
	void TickHeldFire();
	void TickWeaponRecoil();
	void TickViewHandsAnimation(float DeltaSeconds);
	void ResolveViewHandsAnimsForWeapon(FName WeaponDefName);
	void PlayViewHandsAnimation(UAnimSequence* Sequence, bool bLoop);
	void StartViewHandsForEquippedWeapon();
	FName ResolveGripSocketForWeapon(FName WeaponDefName);

	/** Grip socket the equipped weapon is attached to, so Tick can re-pin the viewmodel to it. */
	FName ActiveGripSocket;

	/** Fire ActionMapping held — automatic weapons re-fire from Tick while this is true. */
	bool bFireInputHeld = false;

	/** FrameViewmodel runs per frame now; these keep its diagnostics to one line each. */
	bool bLoggedViewmodelFraming = false;
	bool bLoggedViewmodelSocket = false;

	/** Logged once per def name when the hands skeleton has no matching grip socket. */
	UPROPERTY()
	TSet<FName> LoggedMissingGripSockets;

	/** Cached first-person sequences for the currently equipped weapon def (nulls = none imported). */
	UPROPERTY()
	TObjectPtr<UAnimSequence> ViewHandsEquipAnim;

	UPROPERTY()
	TObjectPtr<UAnimSequence> ViewHandsFidgetAnim;

	UPROPERTY()
	TObjectPtr<UAnimSequence> ViewHandsFireAnim;

	UPROPERTY()
	TObjectPtr<UAnimSequence> ViewHandsReloadAnim;

	UPROPERTY()
	TObjectPtr<UAnimSequence> LastViewHandsAnim;

	FName ViewHandsAnimWeapon = NAME_None;
	bool bViewHandsPlayingOneShot = false;
	float ViewHandsOneShotRemaining = 0.0f;

	UPROPERTY()
	TMap<FName, int32> InventoryStacks;

	UPROPERTY()
	TMap<FName, int32> TipPriorities;

	UPROPERTY()
	TMap<FName, bool> ConceptEnabled;

	UPROPERTY()
	bool bForcedCrouch = false;

	UPROPERTY()
	bool bMovementDisabled = false;

	UPROPERTY()
	TMap<FName, int32> ScriptedSequenceRunNow;

	UPROPERTY()
	FName CurrentInputContext;

	UPROPERTY()
	FName LastInputContext;

	UPROPERTY()
	TMap<FName, uint8> RegionPressure;

	UPROPERTY()
	TSet<FString> Facts;

	UPROPERTY()
	TMap<FName, uint8> QuestState;

	UPROPERTY()
	TMap<FName, int32> QuestObjectiveCount;

	UPROPERTY()
	FName ActiveQuest;

	UPROPERTY()
	TMap<FName, FName> QuestHints;

	UPROPERTY()
	FString LastAutoSaveCommand;

	UPROPERTY()
	float PendingTimerSeconds = 0.0f;

	UPROPERTY()
	FName StoppedTimerLabel;

	UPROPERTY()
	FString LastMapHUDRegion;

	UPROPERTY()
	FName LastTrainingMessage;

	UPROPERTY()
	float FadeVolumeOverride = 1.0f;

	UPROPERTY()
	float FadeVolumeDuration = 0.0f;

	UPROPERTY()
	bool bLevelSavingDisabled = false;

	UPROPERTY()
	bool bLevelSwitchingDisabled = false;

	UPROPERTY()
	FString LastClientMessage;

	UPROPERTY()
	bool bHUDEnabled = true;

	UPROPERTY()
	bool bHUDPlaying = false;

	UPROPERTY()
	bool bSecurityAlarmOn = false;

	UPROPERTY()
	FName LastAlarmTarget;

	UPROPERTY()
	TMap<FName, uint8> SpawnZoneAggressor;

	UPROPERTY()
	TMap<FName, uint8> SpawnZoneProtector;

	UPROPERTY()
	TMap<FName, FName> SpotlightTarget;

	UPROPERTY()
	TMap<FName, bool> SpotlightOn;

	UPROPERTY()
	FName LastQuestLogWait;

	UPROPERTY()
	TMap<FName, float> MaterialSwitchIndex;

	UPROPERTY()
	bool bSecurityHacked = false;

	UPROPERTY()
	float SecurityHackShutdownTime = 0.0f;

	UPROPERTY()
	TMap<FName, bool> TurretHacked;

	UPROPERTY()
	TMap<FName, bool> DoorBroken;

	UPROPERTY()
	TMap<FName, bool> ResurrectionStationActivated;

	UPROPERTY()
	TMap<FName, bool> ResurrectionStationEnabled;

	UPROPERTY()
	TSet<FString> UnlockedBathysphereDestinations;

	UPROPERTY()
	TSet<FName> RemovedHoldables;

	UPROPERTY()
	int32 DeathNotifyCount = 0;

	bool bDeathHandled = false;

	float WeaponRecoilKickRemaining = 0.0f;
	float WeaponRecoilKickTotal = 0.0f;
	FTimerHandle WeaponRecoilTimerHandle;

	double LastPlasmidCastWorldSeconds = -1.0;
};
