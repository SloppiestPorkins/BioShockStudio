#pragma once

#include "GameFramework/Character.h"
#include "ShockPawn.generated.h"

/**
 * UnrealScript `ShockPawn` (super `VPawn`). Capsule radius, walk speed, jump and standing
 * collision height come from the Phase 2 schema JSON at apply-time — they are not authored in
 * this header. `CollisionHeight` is VPawn's override in VengeanceShared.U (68), not Engine.U
 * Pawn's 78.
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
