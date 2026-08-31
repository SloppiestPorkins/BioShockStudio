#pragma once

#include "ShockPawn.h"
#include "ShockPlayer.generated.h"

class AShockWeapon;
class AShockSecurityDevice;
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

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	TObjectPtr<AShockWeapon> EquippedWeapon;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Camera")
	TObjectPtr<UCameraComponent> FirstPersonCamera;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Camera")
	TObjectPtr<USkeletalMeshComponent> ViewHands;

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

	/** Headless verify: ease recoil back without real-time wait. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void AdvanceWeaponRecoilForVerify(float DeltaSeconds);

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

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void ResetForRespawn(float Health);

	virtual void OnDeathFromDamage() override;
	virtual void PossessedBy(AController* NewController) override;
	virtual void SetupPlayerInputComponent(UInputComponent* PlayerInputComponent) override;

private:
	void HandleFireInput();
	void HandleFireReleasedInput();
	void HandleReloadInput();
	void HandlePlasmidInput();
	void HandlePlasmidCycleInput();
	void HandleWeaponNextInput();
	void HandleWeaponPrevInput();
	void HandleWeaponSlot1Input();
	void HandleWeaponSlot2Input();
	void HandleWeaponSlot3Input();
	void HandleWeaponSlot4Input();
	void HandleWeaponSlot5Input();
	void HandleWeaponSlot6Input();
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
	void TickWeaponRecoil();

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
