#pragma once

#include "GameFramework/Actor.h"
#include "ShockWaterVolume.generated.h"

class UBoxComponent;
class UStaticMeshComponent;

/** Water region: overlap logic for plasmids / underwater look, plus a rendered surface plane. */
UCLASS()
class BIOSHOCKRUNTIME_API AShockWaterVolume : public AActor
{
	GENERATED_BODY()

public:
	AShockWaterVolume();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "BioShock|Water")
	TObjectPtr<UBoxComponent> Volume;

	/** Top-face plane sized to the volume XY extent; uses M_ShockWater / cascading MI. */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "BioShock|Water")
	TObjectPtr<UStaticMeshComponent> Surface;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Water")
	bool bIsWater = true;

	/** CascadingWaterVolume / waterfall look — stronger ripples via MI_ShockWater_Cascading. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Water")
	bool bCascading = false;

	/** True when Actor overlaps any AShockWaterVolume with bIsWater. */
	UFUNCTION(BlueprintPure, Category = "BioShock|Water")
	static bool IsActorInWater(const AActor* Actor);

	/** Size the box, place the surface at the top face, assign the water material. */
	UFUNCTION(BlueprintCallable, Category = "BioShock|Water")
	void ConfigureFromHalfExtent(FVector HalfExtent, bool bInCascading);

	/** Re-apply surface transform + material from the current box extent. */
	UFUNCTION(BlueprintCallable, Category = "BioShock|Water")
	void RefreshSurface();

	/** Headless verify: refresh overlap state after editor spawn. */
	UFUNCTION(BlueprintCallable, Category = "BioShock|Water")
	void RefreshOverlapsForVerify();

	UFUNCTION(BlueprintPure, Category = "BioShock|Water|Verify")
	bool HasVisibleSurfaceForVerify() const;
};
