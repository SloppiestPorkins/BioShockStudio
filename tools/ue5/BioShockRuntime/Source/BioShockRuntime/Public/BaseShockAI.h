#pragma once

#include "ShockPawn.h"
#include "ShockAIBrain.h"
#include "BaseShockAI.generated.h"

class UWorld;
class AShockPlayer;
class AShockWeapon;
class UAnimSequence;

UENUM()
enum class EShockAICombatState : uint8
{
	Idle,
	Chase,
	RangedAttack,
	Attack
};

/** Player-readable high-level rhythm reconstructed from EcologyFighter/SearchAction. */
UENUM(BlueprintType)
enum class EShockAIBehaviourState : uint8
{
	Idle,
	Patrol,
	Alert,
	Investigate,
	Search,
	Combat,
	Flee
};

/**
 * UnrealScript `BaseShockAI`. Playable-slice home for a spawnable AI pawn.
 * ScriptLabel mirrors level actor labels for Action* lookups (not a full label system).
 * Minimal 3-state combat tick FSM (Idle / Chase / Attack) — not StateTree.
 */
UCLASS()
class BIOSHOCKRUNTIME_API ABaseShockAI : public AShockPawn
{
	GENERATED_BODY()

public:
	ABaseShockAI();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName ScriptLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName AITypeName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float AuthoredFrozenHealth = 0.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bHasAuthoredFrozenHealth = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	TObjectPtr<AShockPawn> CurrentScriptedAttackTarget;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	TArray<FName> AttackOnSightLabels;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bVisionOn = true;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bHearingOn = true;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bAlwaysSeePlayer = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bAffectVisionOfPlayerOnly = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bMuted = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bToldToWait = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bCanAttack = true;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bVulnerable = true;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bCannotDie = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bCannotBecomeUnconscious = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 ScriptedAIState = 2;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName PatrolName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName MovementDestinationLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString MovementGoalName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 MovementGoalPriority = 0;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bMovementShouldRun = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FVector MovementGoalLocation = FVector::ZeroVector;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	uint8 FullBodyHitReactions = 0;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	uint8 QuickHitReactions = 0;

	/** Runtime gates behind ActionToggleAIReactions; unlike the serialized enum bytes these are
	 * consumed by ReactToHit. */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bUseFullBodyHitReactions = true;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bUseQuickHitReactions = true;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float LODOverrideTime = 0.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 ScriptedSequenceRunNow = 0;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bWaitForGoalSatisfied = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString LastCompletedMovementGoalName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString LastFailedMovementGoalName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bWeaponVisible = true;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bUseCollisionAvoidance = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bHeadTracking = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName HeadTrackTargetLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bHeadTrackingQuickLook = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float HeadTrackDuration = 0.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FVector HeadTrackOffset = FVector::ZeroVector;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Combat")
	float SightRadius = 2200.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Combat")
	float MeleeRange = 180.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Combat")
	float MeleeDamage = 15.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Combat")
	float MeleeCooldown = 1.2f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Combat")
	float RangedRange = 1600.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Combat")
	float RangedCooldown = 1.4f;

	/** PLAUSIBLE cone half-angle in degrees for AI hitscan spread. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Combat")
	float AimSpreadDegrees = 3.0f;

	/** Headless verify hook when spawned geometry does not block ECC_Visibility traces. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Combat")
	bool bSuppressCombatLineOfSight = false;

	/** When true, Chase uses AAIController path-following; missing nav falls back to direct input. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Combat")
	bool bUseNavigation = true;

	/** Aggressor.uc AttackingVisionDecayTime. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Combat")
	float LoseTargetSeconds = 4.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Combat")
	float PerceptionScanInterval = 0.25f;

	/**
	 * When true, any player that passes CanPerceivePlayer (distance / sight cone / LOS) is a valid
	 * combat target — no AttackOnSightLabels entry and no prior damage-aggro required.
	 * Default false keeps scripted-trigger levels unchanged. EditAnywhere + BlueprintReadWrite so
	 * level authors and Python (set_editor_property) can set it; unlike bAlwaysSeePlayer.
	 */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Combat")
	bool bHostileToAnyPlayer = false;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Combat")
	float CorpseFadeSeconds = 5.0f;

	/** When true, UShockAIBrain drives combat; when false, legacy Idle/Chase/Attack FSM runs. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Combat")
	bool bUseBrain = true;

	/** Playable-slice hit flinch: stagger duration base (~0.35 s), scaled slightly by damage fraction. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Combat")
	float HitStaggerSeconds = 0.35f;

	/** Knockback impulse magnitude base (~250), scaled and clamped per hit. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Combat")
	float HitKnockback = 250.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Combat")
	bool bAggroOnDamage = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Combat")
	TObjectPtr<AShockWeapon> AIWeapon;

	UFUNCTION(BlueprintCallable, Category="BioShock|Combat")
	void EquipAIWeapon(AShockWeapon* Weapon);

	UFUNCTION(BlueprintCallable, Category="BioShock|Combat")
	void SetSuppressCombatLineOfSight(bool bSuppress);

	UFUNCTION(BlueprintPure, Category="BioShock|Combat")
	bool HasAIWeapon() const { return AIWeapon != nullptr; }

	UFUNCTION(BlueprintPure, Category="BioShock|Combat")
	int32 GetAIWeaponFireCount() const;

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	void ConfigureIdentity(FName InType, FName InLabel);

	/** Apply imported archetype data when present; no-op when lookup misses. */
	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	void ApplyArchetypeLookup(FName LookupKey);

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	FName GetScriptLabel() const { return ScriptLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	void ScriptedAttackTarget(AShockPawn* Target);

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	void AddTargetToAttackOnSight(FName InTargetLabel);

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	AShockPawn* GetScriptedAttackTarget() const { return CurrentScriptedAttackTarget; }

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	bool HasAttackOnSightLabel(FName InTargetLabel) const;

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	bool IsVisionOn() const { return bVisionOn; }

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	bool IsHearingOn() const { return bHearingOn; }

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	bool IsMuted() const { return bMuted; }

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	bool IsToldToWait() const { return bToldToWait; }

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	bool CanAttack() const { return bCanAttack; }

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	bool IsVulnerable() const { return bVulnerable; }

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	bool CannotDie() const { return bCannotDie; }

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	bool CannotBecomeUnconscious() const { return bCannotBecomeUnconscious; }

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	int32 GetScriptedAIState() const { return ScriptedAIState; }

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	FName GetPatrolName() const { return PatrolName; }

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	FName GetMovementDestinationLabel() const { return MovementDestinationLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	bool GetAlwaysSeePlayer() const { return bAlwaysSeePlayer; }

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	uint8 GetFullBodyHitReactions() const { return FullBodyHitReactions; }

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	uint8 GetQuickHitReactions() const { return QuickHitReactions; }

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	void SetScriptedUseFullBodyHitReactions(bool bUse);

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	void SetScriptedUseQuickHitReactions(bool bUse);

	UFUNCTION(BlueprintPure, Category="BioShock|AI")
	bool UsesFullBodyHitReactions() const { return bUseFullBodyHitReactions; }

	UFUNCTION(BlueprintPure, Category="BioShock|AI")
	bool UsesQuickHitReactions() const { return bUseQuickHitReactions; }

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	float GetLODOverrideTime() const { return LODOverrideTime; }

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	int32 GetScriptedSequenceRunNow() const { return ScriptedSequenceRunNow; }

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	bool IsWaitForGoalSatisfied() const { return bWaitForGoalSatisfied; }

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	FString GetMovementGoalName() const { return MovementGoalName; }

	/** Minimal Tyrion-compatible lifecycle used by Post/Remove/WaitForGoal. */
	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	void PostScriptedMovementGoal(
		FName DestinationLabel,
		const FString& GoalName,
		int32 Priority,
		bool bShouldRun,
		FVector Destination);

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	bool RemoveScriptedMovementGoal(const FString& GoalName);

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	void CompleteScriptedMovementGoal(bool bAchieved);

	UFUNCTION(BlueprintPure, Category="BioShock|AI")
	bool HasCompletedMovementGoal(const FString& GoalName) const;

	UFUNCTION(BlueprintPure, Category="BioShock|AI")
	bool HasFailedMovementGoal(const FString& GoalName) const;

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	void SetAttachmentCategoryHidden(FName Category, bool bHideAttachments);

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	bool IsAttachmentCategoryHidden(FName Category) const;

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	void SetWeaponVisible(bool bVisible);

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	bool IsWeaponVisible() const { return bWeaponVisible; }

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	void SetCollisionAvoidanceEnabled(bool bEnabled);

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	bool IsCollisionAvoidanceEnabled() const { return bUseCollisionAvoidance; }

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	void BeginHeadTracking(FName TargetLabel, bool bQuickLook, float InDuration, FVector InOffset);

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	bool IsHeadTracking() const { return bHeadTracking; }

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	FName GetHeadTrackTargetLabel() const { return HeadTrackTargetLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	bool IsHeadTrackingQuickLook() const { return bHeadTrackingQuickLook; }

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	float GetHeadTrackDuration() const { return HeadTrackDuration; }

	/** Editor actor label or ScriptLabel. Not a UFunction — C++ action helpers only. */
	static TArray<ABaseShockAI*> CollectLabeled(UWorld* World, FName Label);

	/** Called from UShockDamageLibrary when a ShockPlayer damages this AI. */
	void NotifyAggroFromPlayer(AShockPawn* DamageInstigator);

	/** Live-hit feedback: stagger, knockback, mesh flash. Called from ApplyDamage on surviving AI. */
	void ReactToHit(float Amount, AActor* DamageInstigator);

	/** Plasmid stun — longer HitReact window than weapon flinch (Electro Bolt). */
	void ReactToPlasmidStun(float Duration, AActor* DamageInstigator);

	/** Incinerate burn — ticking damage while BurningRemaining > 0. */
	void Ignite(float Seconds, float Dps, AActor* DamageInstigator);

	/** Chemical-thrower freeze beam — slows movement while ChillRemaining > 0. */
	void ApplyChill(float Seconds);

	/** Winter Blast — hard freeze (movement/brain off, physics frozen, shatter on damage). */
	void FreezeSolid(float Seconds, AActor* DamageInstigator);

	/** Enrage — treat other AIs as hostile; ignore the player while active. */
	void ApplyEnrage(float Seconds, AActor* DamageInstigator);

	UFUNCTION(BlueprintPure, Category = "BioShock|Combat")
	float GetBurningRemaining() const { return BurningRemaining; }

	UFUNCTION(BlueprintPure, Category = "BioShock|Combat")
	float GetChillRemaining() const { return ChillRemaining; }

	UFUNCTION(BlueprintPure, Category = "BioShock|Combat")
	float GetFrozenSolidRemaining() const { return FrozenSolidRemaining; }

	UFUNCTION(BlueprintPure, Category = "BioShock|Combat")
	float GetEnragedRemaining() const { return EnragedRemaining; }

	UFUNCTION(BlueprintPure, Category = "BioShock|Combat")
	bool IsEnraged() const { return EnragedRemaining > 0.0f; }

	/** Nearest living ABaseShockAI other than self (Enrage target pick). */
	AShockPawn* FindNearestOtherAIForEnrage() const;

	/** Headless verify: current MaxWalkSpeed after combat movement multipliers. */
	UFUNCTION(BlueprintPure, Category = "BioShock|Combat")
	float GetMaxWalkSpeedForVerify() const;

	/** Headless verify helper: runs Tick plus movement so AddMovementInput advances. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Combat")
	void AdvanceAutonomousCombat(float DeltaSeconds);

	/** Headless verify: spawn default AAIController when editor spawn skipped BeginPlay. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Combat")
	void EnsureControllerForVerify();

	/** UC PrepareToResurrect equivalent: forget the dead player, preserving this AI's health. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Combat")
	void HandlePlayerRespawned();

	UFUNCTION(BlueprintPure, Category="BioShock|Combat")
	bool IsCombatLoopActive() const { return !bCombatLoopStopped; }

	UFUNCTION(BlueprintPure, Category="BioShock|Combat")
	int32 GetDeathNotifyCount() const { return DeathNotifyCount; }

	UFUNCTION(BlueprintPure, Category="BioShock|Combat")
	bool IsNavChaseActive() const { return bNavChaseActive; }

	UFUNCTION(BlueprintPure, Category="BioShock|Combat")
	bool IsNavUsingFallback() const { return bNavUsingFallback; }

	UFUNCTION(BlueprintPure, Category="BioShock|Combat")
	float GetHitReactRemaining() const { return HitReactRemaining; }

	UFUNCTION(BlueprintPure, Category="BioShock|Combat|Brain")
	bool IsUsingBrain() const { return bUseBrain; }

	UFUNCTION(BlueprintPure, Category="BioShock|Combat|Brain")
	UShockAIBrain* GetShockAIBrain() const { return Brain; }

	UFUNCTION(BlueprintPure, Category="BioShock|AI")
	EShockAIBehaviourState GetBehaviourState() const { return BehaviourState; }

	UFUNCTION(BlueprintPure, Category="BioShock|AI")
	FName GetBehaviourStateName() const;

	UFUNCTION(BlueprintPure, Category="BioShock|AI")
	FVector GetLastKnownTargetLocation() const { return LastKnownTargetLocation; }

	/** Hearing entry point for footsteps, weapons, glass, script events, and headless verification. */
	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	void NotifySuspiciousNoise(FVector NoiseLocation, float Loudness, FName NoiseCategory);

	/** BioShock SpawningManager propagation: every living splicer within Radius hears the event. */
	static void BroadcastSuspiciousNoise(
		UWorld* World,
		FVector NoiseLocation,
		float Loudness,
		FName NoiseCategory,
		AActor* Source,
		float Radius);

	/** Headless sight hook; follows the same state-entry path as a real perception acquisition. */
	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	void SimulateSightEvent(AShockPawn* Target);

	/** UC pistol profile: 5-7 shot bursts, then 2-4 seconds reposition/reload cover time. */
	void TickRangedCombatCadence(float DeltaSeconds);

	/** Headless verify: name of the AnimSequence currently installed via PlayAnimation. */
	UFUNCTION(BlueprintPure, Category="BioShock|Combat")
	FName GetPlayingAnimationNameForVerify() const;

	/**
	 * Headless verify: world-space head.Z - feet.Z after mesh assign. Positive and large means
	 * upright; large negative means inverted. Returns 0 when bones/mesh are missing.
	 */
	UFUNCTION(BlueprintPure, Category="BioShock|Combat")
	float GetMeshUprightDeltaForVerify() const;

	/** Cache the authored hit used if this damage kills the AI. */
	void RecordRagdollHit(FVector Impulse, FVector HitLocation, FName HitBone);

	UFUNCTION(BlueprintPure, Category="BioShock|Combat")
	bool IsRagdollActiveForVerify() const { return bRagdollActive; }

	/**
	 * Assign a full-body BioShock skeletal mesh onto an ACharacter mesh component.
	 * Sets visibility, optional mesh collision off (capsule keeps collision), and relative
	 * rotation Identity — see ApplyCombatSkeletalMesh in BaseShockAI.cpp.
	 */
	static void ApplyCombatSkeletalMesh(
		USkeletalMeshComponent* Body,
		USkeletalMesh* MeshAsset,
		bool bDisableMeshCollision = true);

	/** Combat helpers used by UShockAIAbility — surface moved from TickCombat FSM. */
	AShockPawn* GetCombatTargetPawn() const { return CombatTarget; }
	AShockPawn* GetCurrentScriptedAttackTargetPawn() const { return CurrentScriptedAttackTarget; }
	void SetCombatTargetPawn(AShockPawn* Target);
	void ClearCombatTargetPawn();
	bool IsAliveCombatTarget(const AShockPawn* Target) const;
	float GetDistanceToCombatTarget(const AShockPawn* Target) const;
	void FaceCombatTarget(const AShockPawn* Target);
	bool HasCombatLineOfSightTo(const AShockPawn* Target) const;
	void StopCombatNavChase();
	bool TryTickCombatNavChase(AShockPawn* Target, float DeltaSeconds);
	void TickCombatChaseDirectMovement(AShockPawn* Target, float DeltaSeconds);
	void TryCombatRangedFire();
	float GetMeleeCooldownRemaining() const { return MeleeCooldownRemaining; }
	void SetMeleeCooldownRemaining(float Value) { MeleeCooldownRemaining = Value; }
	float GetRangedCooldownRemaining() const { return RangedCooldownRemaining; }
	void SetRangedCooldownRemaining(float Value) { RangedCooldownRemaining = Value; }
	float GetOutOfSightTimer() const { return OutOfSightTimer; }
	void SetOutOfSightTimer(float Value) { OutOfSightTimer = Value; }
	void TickBrainIdlePerception(float DeltaSeconds);

	virtual void OnDeathFromDamage() override;

	/** Switch to gravity-free flying — for headless verification / floorless test maps only.
	 *  Real play keeps the default walking mode. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Combat")
	void EnableFloorlessMovement();

	virtual void Tick(float DeltaSeconds) override;

private:
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Combat|Brain", meta=(AllowPrivateAccess="true"))
	TObjectPtr<UShockAIBrain> Brain;

	UPROPERTY()
	TMap<FName, bool> HiddenAttachmentCategories;

	UPROPERTY()
	TObjectPtr<AShockPawn> CombatTarget;

	UPROPERTY()
	TObjectPtr<AShockPawn> AggroInstigator;

	UPROPERTY()
	EShockAICombatState CombatState = EShockAICombatState::Idle;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|AI", meta=(AllowPrivateAccess="true"))
	EShockAIBehaviourState BehaviourState = EShockAIBehaviourState::Idle;

	UPROPERTY()
	FVector LastKnownTargetLocation = FVector::ZeroVector;

	UPROPERTY()
	FVector LastKnownTargetDirection = FVector::ZeroVector;

	UPROPERTY()
	FVector StateMoveDestination = FVector::ZeroVector;

	float BehaviourStateSeconds = 0.0f;
	float SearchDurationSeconds = 0.0f;
	float SearchTurnAccumulator = 0.0f;
	float RangedRepositionRemaining = 0.0f;
	int32 RangedBurstShotsRemaining = 0;
	bool bGroupAlertSent = false;
	bool bFledAtCurrentLowHealth = false;

	UPROPERTY()
	float PerceptionScanAccumulator = 0.0f;

	UPROPERTY()
	float MeleeCooldownRemaining = 0.0f;

	UPROPERTY()
	float RangedCooldownRemaining = 0.0f;

	UPROPERTY()
	float OutOfSightTimer = 0.0f;

	UPROPERTY()
	bool bCombatLoopStopped = false;

	UPROPERTY()
	int32 DeathNotifyCount = 0;

	UPROPERTY()
	bool bNavChaseActive = false;

	UPROPERTY()
	bool bNavUsingFallback = false;

	UPROPERTY()
	FVector NavLastMoveGoal = FVector::ZeroVector;

	UPROPERTY()
	float NavMoveRefreshTimer = 0.0f;

	bool bDeathReactionHandled = false;

	UPROPERTY()
	float HitReactRemaining = 0.0f;

	UPROPERTY()
	float HitReactRateLimitRemaining = 0.0f;

	UPROPERTY()
	float BurningRemaining = 0.0f;

	UPROPERTY()
	float ChillRemaining = 0.0f;

	UPROPERTY()
	float FrozenSolidRemaining = 0.0f;

	UPROPERTY()
	TObjectPtr<AActor> FrozenInstigator;

	UPROPERTY()
	float EnragedRemaining = 0.0f;

	UPROPERTY()
	float BurningDps = 0.0f;

	UPROPERTY()
	TObjectPtr<AActor> BurningInstigator;

	float BurningLogAccumulator = 0.0f;
	float FrozenLogAccumulator = 0.0f;

	UPROPERTY()
	TObjectPtr<class UMaterialInstanceDynamic> HitFlashOverlayMID;

	UPROPERTY()
	bool bHitFlashUsesOverlay = false;

	UPROPERTY()
	bool bHitFlashUsesCustomDepth = false;

	FTimerHandle CorpseFadeTimer;
	FTimerHandle HitFlashTimerHandle;

	FVector PendingRagdollImpulse = FVector::ZeroVector;
	FVector PendingRagdollHitLocation = FVector::ZeroVector;
	FName PendingRagdollHitBone = NAME_None;
	float RagdollBlendWeight = 0.0f;
	bool bRagdollActive = false;

	static constexpr float HitReactRateLimitSeconds = 0.15f;
	static constexpr float HitFlashSeconds = 0.12f;
	static constexpr float HitReactMovementScale = 0.4f;
	static constexpr float ChillMovementScale = 0.4f;

	void HideCorpse();
	void StartRagdoll();
	void TickRagdollBlend(float DeltaSeconds);
	void ClearHitFlash();
	void ApplyHitFlash();
	void ApplyBurnFlash();
	void ApplyFrozenFlash();
	void ClearFrozenState();
	void TickStatusEffects(float DeltaSeconds);
	bool TickScriptedMovementGoal(float DeltaSeconds);
	void TickCombat(float DeltaSeconds);
	void TickCombatFsm(float DeltaSeconds);
	void TickCombatCooldowns(float DeltaSeconds);
	void TickCombatMovementSpeed(float DeltaSeconds);
	void StopNavChase();
	bool TryTickNavChase(AShockPawn* Target, float DeltaSeconds);
	void TickChaseDirectMovement(AShockPawn* Target, float DeltaSeconds);
	bool IsCombatLoopGated() const;
	bool IsAliveTarget(const AShockPawn* Target) const;
	void SetCombatTarget(AShockPawn* Target);
	void ClearCombatTarget();
	float DistanceToTarget(const AShockPawn* Target) const;
	void FaceTargetYaw(const AShockPawn* Target);
	bool HasClearLineOfSightTo(const AShockPawn* Target) const;
	FVector ApplyAimSpread(FVector Direction) const;
	void TryRangedFire();
	void SpawnArchetypeWeaponIfNeeded(const class UShockAiArchetype* Archetype);
	bool CanPerceivePlayer(const AShockPlayer* Player) const;
	bool TryAcquireTargetFromPerception();
	FName GetPlayerPerceptionLabel(const AShockPlayer* Player) const;
	void TickBehaviour(float DeltaSeconds);
	void EnterBehaviourState(EShockAIBehaviourState NewState);
	void TickMoveToLocation(FVector Destination, float DeltaSeconds, float AcceptanceRadius);
	void AlertNearbySplicers();
	bool IsBelowFleeThreshold() const;

	void EnsureCombatMeshAndAnims();
	void TickAnimationDriver(float DeltaSeconds);
	void PlayCombatAnimation(UAnimSequence* Sequence, bool bLoop);
	UAnimSequence* ResolveAnimationForAbility(FName AbilityName) const;
	static bool IsOneShotAbilityName(FName AbilityName);

	UPROPERTY()
	TObjectPtr<UAnimSequence> AnimIdle;

	UPROPERTY()
	TObjectPtr<UAnimSequence> AnimWalk;

	UPROPERTY()
	TObjectPtr<UAnimSequence> AnimRun;

	UPROPERTY()
	TObjectPtr<UAnimSequence> AnimMelee;

	UPROPERTY()
	TObjectPtr<UAnimSequence> AnimHitReact;

	UPROPERTY()
	TObjectPtr<UAnimSequence> AnimDeath;

	UPROPERTY()
	TObjectPtr<UAnimSequence> LastPlayedAnim;

	FName LastAnimAbilityName = NAME_None;
	bool bAnimAssetsLoaded = false;
	bool bPlayingOneShotAnim = false;
	float OneShotAnimRemaining = 0.0f;
	bool bDeathAnimStarted = false;
	bool bPoseLogged = false;
};
