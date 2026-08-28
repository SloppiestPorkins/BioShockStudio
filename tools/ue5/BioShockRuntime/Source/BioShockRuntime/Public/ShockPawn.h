#pragma once

#include "GameFramework/Character.h"
#include "ShockPawn.generated.h"

class UWorld;

/**
 * UnrealScript `ShockPawn` (super `VPawn`). Capsule radius, walk speed, jump and standing
 * collision height come from the Phase 2 schema JSON at apply-time — they are not authored in
 * this header. `CollisionHeight` is VPawn's override in VengeanceShared.U (68), not Engine.U
 * Pawn's 78.
 *
 * AuthoredHealth / AuthoredMaxHealth are schema fields. CurrentHealth is a playable-slice
 * stand-in tracker; it is not UE's damage pipeline or BioShock's HitPoints system.
 */
UCLASS()
class BIOSHOCKRUNTIME_API AShockPawn : public ACharacter
{
	GENERATED_BODY()

public:
	AShockPawn();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString SchemaClassName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float AuthoredHealth = 0.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float AuthoredMaxHealth = 0.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float CurrentHealth = 0.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bIsDead = false;

	/** Playable-slice god-mode flag for ActionSetPawnInvincibility / SetPlayerInvincibility. */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bInvincible = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bPhysicsDisabled = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bRootMotionWhenPhysicsDisabled = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Pawn")
	void SetInvincible(bool bInInvincible) { bInvincible = bInInvincible; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Pawn")
	bool IsInvincible() const { return bInvincible; }

	/** Seeds CurrentHealth from AuthoredMaxHealth (or AuthoredHealth). Idempotent if already > 0. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Pawn")
	void EnsureHealthInitialized();

	/**
	 * Subtracts Damage from CurrentHealth. Returns remaining health.
	 * Playable-slice stand-in — no armor, plasmids, or death anims.
	 */
	UFUNCTION(BlueprintCallable, Category="BioShock|Pawn")
	float ApplyAuthoredDamage(float Damage);

	UFUNCTION(BlueprintCallable, Category="BioShock|Pawn")
	float GetCurrentHealth() const { return CurrentHealth; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Pawn")
	bool IsDead() const { return bIsDead; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Pawn")
	void SetScriptedPhysicsDisabled(bool bDisable, bool bRootMotion);

	UFUNCTION(BlueprintCallable, Category="BioShock|Pawn")
	bool IsPhysicsDisabled() const { return bPhysicsDisabled; }

	/** Editor actor label, or BaseShockAI ScriptLabel. C++ action helper only. */
	static TArray<AShockPawn*> CollectLabeled(UWorld* World, FName Label);
};
