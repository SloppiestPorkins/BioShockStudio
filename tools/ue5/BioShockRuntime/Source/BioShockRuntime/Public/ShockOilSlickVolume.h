#pragma once

#include "GameFramework/Actor.h"
#include "ShockOilSlickVolume.generated.h"

class AShockPawn;
class AShockPlayer;
class UBoxComponent;

/** Headless / slice oil marker for Incinerate synergy (mirrors AShockWaterVolume). */
UCLASS()
class BIOSHOCKRUNTIME_API AShockOilSlickVolume : public AActor
{
	GENERATED_BODY()

public:
	AShockOilSlickVolume();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "BioShock|Oil")
	TObjectPtr<UBoxComponent> Volume;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Oil")
	bool bIsOil = true;

	/** One-shot: slick is consumed after first ignite. */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "BioShock|Oil")
	bool bIgnited = false;

	/** True when Actor overlaps any non-ignited AShockOilSlickVolume with bIsOil. */
	UFUNCTION(BlueprintPure, Category = "BioShock|Oil")
	static bool IsActorInOil(const AActor* Actor);

	/** Find a non-ignited slick overlapping Actor or containing Point. */
	UFUNCTION(BlueprintPure, Category = "BioShock|Oil")
	static AShockOilSlickVolume* FindSlickForActorOrPoint(UWorld* World, const AActor* Actor, FVector Point);

	/** Ignite every pawn in this slick; consumes the slick (bIgnited). */
	UFUNCTION(BlueprintCallable, Category = "BioShock|Oil")
	void IgniteSlick(AShockPlayer* Caster, float BurstDamage, float BurnSeconds, float BurnDps);

	UFUNCTION(BlueprintPure, Category = "BioShock|Oil")
	bool IsActorOverlapping(const AActor* Actor) const;

	/** Headless verify: refresh overlap state after editor spawn. */
	UFUNCTION(BlueprintCallable, Category = "BioShock|Oil")
	void RefreshOverlapsForVerify();
};
