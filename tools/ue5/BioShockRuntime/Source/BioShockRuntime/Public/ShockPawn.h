#pragma once

#include "GameFramework/Character.h"
#include "ShockPawn.generated.h"

/**
 * UnrealScript `ShockPawn` (super `VPawn`). Capsule radius, walk speed and jump come from the
 * Phase 2 schema JSON at apply-time — they are not authored in this header.
 *
 * Standing `CollisionHeight` is not in ShockGame.U; it lives on the Engine.U parent we cannot
 * decompile. It is left at the UE5 Character default and reported as UNKNOWN.
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
};
