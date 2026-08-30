#pragma once

#include "Kismet/BlueprintFunctionLibrary.h"
#include "ShockPhysicsLibrary.generated.h"

class AActor;
class UWorld;

/**
 * Single playable-slice physics path for scripted impulses, Havok-force stand-ins, and freeze.
 * Havok force fields / joint limits are PLAUSIBLE Chaos approximations (licence-blocked).
 */
UCLASS()
class BIOSHOCKRUNTIME_API UShockPhysicsLibrary : public UBlueprintFunctionLibrary
{
	GENERATED_BODY()

public:
	/** Editor actor label or BaseShockAI ScriptLabel (delegates to UShockDamageLibrary). */
	UFUNCTION(BlueprintCallable, Category="BioShock|Physics")
	static AActor* FindActorByLabel(UWorld* World, FName Label);

	/** Applies Impulse to simulating primitives; optionally wakes the root body first. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Physics")
	static int32 ApplyImpulse(AActor* Target, FVector Impulse, bool bVelChange, bool bWakeIfNeeded = true);

	/** Radial impulse on simulating primitives within Radius; linear falloff to zero at edge. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Physics")
	static int32 ApplyRadialImpulse(
		UWorld* World,
		FVector Origin,
		float Radius,
		float Strength,
		bool bVelChange);

	/**
	 * Freeze: disable simulation and sleep. Unfreeze: restore prior simulate state;
	 * bForceSimulateOnUnfreeze wakes even when the body was static before freeze.
	 */
	UFUNCTION(BlueprintCallable, Category="BioShock|Physics")
	static bool SetActorPhysicsFrozen(AActor* Target, bool bFrozen, bool bForceSimulateOnUnfreeze = false);

	/** PLAUSIBLE gate for ActionEnableOrDisableHavokForceActor (defaults enabled). */
	UFUNCTION(BlueprintCallable, Category="BioShock|Physics")
	static void SetHavokForceActorEnabled(FName Label, bool bEnabled);

	UFUNCTION(BlueprintCallable, Category="BioShock|Physics")
	static bool IsHavokForceActorEnabled(FName Label);

	/** Headless -game self-test; logs via caller. Editor commandlet has no Chaos sim. */
	static bool RunHeadlessSelfTest(UWorld* World, FString& OutError);
};
