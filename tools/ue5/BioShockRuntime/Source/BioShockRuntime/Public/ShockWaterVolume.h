#pragma once

#include "GameFramework/Actor.h"
#include "ShockWaterVolume.generated.h"

class UBoxComponent;

/** Headless / slice water marker for Electro Bolt synergy (bIsWater overlap test). */
UCLASS()
class BIOSHOCKRUNTIME_API AShockWaterVolume : public AActor
{
	GENERATED_BODY()

public:
	AShockWaterVolume();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "BioShock|Water")
	TObjectPtr<UBoxComponent> Volume;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Water")
	bool bIsWater = true;

	/** True when Actor overlaps any AShockWaterVolume with bIsWater. */
	UFUNCTION(BlueprintPure, Category = "BioShock|Water")
	static bool IsActorInWater(const AActor* Actor);

	/** Headless verify: refresh overlap state after editor spawn. */
	UFUNCTION(BlueprintCallable, Category = "BioShock|Water")
	void RefreshOverlapsForVerify();
};
