#pragma once

#include "Kismet/BlueprintFunctionLibrary.h"
#include "ShockDamageLibrary.generated.h"

class AActor;
class AShockPlayer;
class UWorld;

/**
 * Single playable-slice damage path for hitscan, scripted actions, and future combat.
 * Honors ShockPawn::bInvincible and BaseShockAI vulnerability / cannot-die flags.
 */
UCLASS()
class BIOSHOCKRUNTIME_API UShockDamageLibrary : public UBlueprintFunctionLibrary
{
	GENERATED_BODY()

public:
	/** Returns damage actually applied (0 when blocked or target already dead). */
	UFUNCTION(BlueprintCallable, Category="BioShock|Combat")
	static float ApplyDamage(
		AActor* Target,
		float Amount,
		AActor* Instigator,
		FName DamageType,
		FVector HitImpulseDirection = FVector::ZeroVector,
		FVector HitLocation = FVector::ZeroVector,
		FName HitBone = NAME_None);

	/**
	 * Damages ShockPawns within OuterRadius of Origin. Full Amount at or inside InnerRadius;
	 * linear falloff to zero at OuterRadius.
	 */
	UFUNCTION(BlueprintCallable, Category="BioShock|Combat")
	static int32 ApplyRadialDamage(
		UWorld* World,
		FVector Origin,
		float OuterRadius,
		float Amount,
		AActor* Instigator,
		FName DamageType,
		float InnerRadius = 0.0f);

	/** Editor actor label or BaseShockAI ScriptLabel. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Combat")
	static AActor* FindActorByLabel(UWorld* World, FName Label);

	/** Walk instigator then owner chain for the player that authored damage. */
	static AShockPlayer* ResolvePlayerFrom(AActor* Source);
};
