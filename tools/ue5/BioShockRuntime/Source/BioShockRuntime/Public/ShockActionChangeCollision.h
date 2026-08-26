#pragma once

#include "ShockAction.h"
#include "ShockActionChangeCollision.generated.h"

class AActor;

/** Mirrors UnrealScript ActionChangeCollision.CollisionChangeType. */
UENUM(BlueprintType)
enum class EShockCollisionChange : uint8
{
	SetToTrue = 0,
	SetToFalse = 1,
	DoNotChange = 2,
};

/**
 * UnrealScript `ActionChangeCollision`: per-flag SetToTrue / SetToFalse / DoNotChange on a
 * labeled actor. First slice applies CollideActors → SetActorEnableCollision; other flags are
 * held for later. Label foreach still open.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionChangeCollision : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionChangeCollision();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName TargetLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	EShockCollisionChange CollideActors = EShockCollisionChange::DoNotChange;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	EShockCollisionChange CollideWorld = EShockCollisionChange::DoNotChange;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	EShockCollisionChange BlockActors = EShockCollisionChange::DoNotChange;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	EShockCollisionChange BlockPlayers = EShockCollisionChange::DoNotChange;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	EShockCollisionChange BlockNonZeroExtentTraces = EShockCollisionChange::DoNotChange;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	EShockCollisionChange WorldGeometry = EShockCollisionChange::DoNotChange;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	EShockCollisionChange BlockHavok = EShockCollisionChange::DoNotChange;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bLastAppliedEnableCollision = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bDidApplyCollideActors = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InTargetLabel, EShockCollisionChange InCollideActors);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	EShockCollisionChange GetCollideActors() const { return CollideActors; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool DidApplyCollideActors() const { return bDidApplyCollideActors; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetLastAppliedEnableCollision() const { return bLastAppliedEnableCollision; }

	/** Applies CollideActors to SetActorEnableCollision when not DoNotChange. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool ApplyToActor(AActor* Target);
};
