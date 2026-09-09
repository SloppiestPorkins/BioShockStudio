#pragma once

#include "GameFramework/Actor.h"
#include "ShockPlasmid.h"
#include "ShockCycloneTrapPlasmid.generated.h"

class AShockPlayer;
class UStaticMeshComponent;
class USphereComponent;

/**
 * The placed trap from Cyclone Trap. Overlap-only sphere; the first character to step on it is
 * flung straight up, then the trap expires.
 */
UCLASS()
class BIOSHOCKRUNTIME_API AShockCycloneTrap : public AActor
{
	GENERATED_BODY()

public:
	AShockCycloneTrap();

	virtual void BeginPlay() override;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "BioShock|Plasmid|CycloneTrap")
	TObjectPtr<USphereComponent> Trigger;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "BioShock|Plasmid|CycloneTrap")
	TObjectPtr<UStaticMeshComponent> Marker;

	/** PLAUSIBLE — vertical launch speed; the shipped vortex force is native. */
	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "BioShock|Plasmid|CycloneTrap")
	float LaunchSpeed = 1500.0f;

	UFUNCTION(BlueprintPure, Category = "BioShock|Plasmid|CycloneTrap")
	bool WasTriggeredForVerify() const { return bTriggered; }

private:
	UFUNCTION()
	void OnTrapOverlap(
		UPrimitiveComponent* OverlappedComponent,
		AActor* OtherActor,
		UPrimitiveComponent* OtherComp,
		int32 OtherBodyIndex,
		bool bFromSweep,
		const FHitResult& SweepResult);

	bool bTriggered = false;
};

/**
 * UnrealScript `SpringBoardTrapAbility` (Cyclone Trap). `BioAmmoCost=16`. Places a trap at the
 * aim point. Native radius/force are unavailable, so the placed `AShockCycloneTrap` uses a
 * PLAUSIBLE 90 uu trigger and a fixed vertical launch.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockCycloneTrapPlasmid : public UShockPlasmid
{
	GENERATED_BODY()

public:
	UShockCycloneTrapPlasmid();

	virtual bool Cast(AShockPlayer* Caster, const FHitResult& Aim) override;

	UFUNCTION(BlueprintPure, Category = "BioShock|Plasmid|CycloneTrap")
	AShockCycloneTrap* GetLastTrapForVerify() const { return LastTrap.Get(); }

private:
	UPROPERTY(Transient)
	TWeakObjectPtr<AShockCycloneTrap> LastTrap;
};
