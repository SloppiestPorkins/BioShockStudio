#pragma once

#include "ShockPawn.h"
#include "ShockAIBrain.h"
#include "BaseShockAI.generated.h"

class UWorld;
class AShockPlayer;
class AShockWeapon;

UENUM()
enum class EShockAICombatState : uint8
{
	Idle,
	Chase,
	RangedAttack,
	Attack
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

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float LODOverrideTime = 0.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 ScriptedSequenceRunNow = 0;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bWaitForGoalSatisfied = false;

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
	float SightRadius = 2500.0f;

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

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Combat")
	float LoseTargetSeconds = 5.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Combat")
	float PerceptionScanInterval = 0.25f;

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
	float GetLODOverrideTime() const { return LODOverrideTime; }

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	int32 GetScriptedSequenceRunNow() const { return ScriptedSequenceRunNow; }

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	bool IsWaitForGoalSatisfied() const { return bWaitForGoalSatisfied; }

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	FString GetMovementGoalName() const { return MovementGoalName; }

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

	UFUNCTION(BlueprintPure, Category = "BioShock|Combat")
	float GetBurningRemaining() const { return BurningRemaining; }

	/** Headless verify helper: runs Tick plus movement so AddMovementInput advances. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Combat")
	void AdvanceAutonomousCombat(float DeltaSeconds);

	/** Headless verify: spawn default AAIController when editor spawn skipped BeginPlay. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Combat")
	void EnsureControllerForVerify();

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
	float BurningDps = 0.0f;

	UPROPERTY()
	TObjectPtr<AActor> BurningInstigator;

	float BurningLogAccumulator = 0.0f;

	UPROPERTY()
	TObjectPtr<class UMaterialInstanceDynamic> HitFlashOverlayMID;

	UPROPERTY()
	bool bHitFlashUsesOverlay = false;

	UPROPERTY()
	bool bHitFlashUsesCustomDepth = false;

	FTimerHandle CorpseFadeTimer;
	FTimerHandle HitFlashTimerHandle;

	static constexpr float HitReactRateLimitSeconds = 0.15f;
	static constexpr float HitFlashSeconds = 0.12f;
	static constexpr float HitReactMovementScale = 0.4f;

	void HideCorpse();
	void ClearHitFlash();
	void ApplyHitFlash();
	void ApplyBurnFlash();
	void TickStatusEffects(float DeltaSeconds);
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
};
