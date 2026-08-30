#pragma once

#include "ShockPawn.h"
#include "ShockPlayer.generated.h"

class AShockWeapon;
class UCameraComponent;
class UInputComponent;
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
	 * UnrealScript `ShockPlayer.AddStackToInventory` stand-in: merge StackSize into the
	 * named ItemClass. No Item actors, no UI warnings, no max-stack clamp.
	 * Returns the new stack total, or 0 if the grant is refused.
	 */
	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	int32 AddStackToInventory(FName ItemClass, int32 StackSize);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	int32 RemoveStackFromInventory(FName ItemClass, int32 StackSize);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	int32 GetInventoryStack(FName ItemClass) const;

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

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void ResetForRespawn(float Health);

	virtual void OnDeathFromDamage() override;
	virtual void PossessedBy(AController* NewController) override;
	virtual void SetupPlayerInputComponent(UInputComponent* PlayerInputComponent) override;

private:
	void HandleFireInput();
	void MoveForward(float Value);
	void MoveRight(float Value);
	void TurnAtRate(float Value);
	void LookUpAtRate(float Value);
	void EnsureViewHands();
	void FrameViewmodel(FName GripSocket);

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
};
