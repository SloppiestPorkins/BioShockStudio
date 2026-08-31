#pragma once

#include "GameFramework/Actor.h"
#include "ShockBathysphereStation.generated.h"

class UBoxComponent;

/**
 * Bathysphere travel trigger (stretch). Overlap + Interact when unlocked.
 * Route-map UI and full bathysphere mode are still TODO.
 */
UCLASS()
class BIOSHOCKRUNTIME_API AShockBathysphereStation : public AActor
{
	GENERATED_BODY()

public:
	AShockBathysphereStation();

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Bathysphere")
	FString DestinationMap;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Bathysphere")
	FName DestinationStart;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Bathysphere")
	bool bUnlocked = false;

	/** Match ActionUnlockBathysphereDestination::MapName against this map id. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Bathysphere")
	FName StationMapId;

	UFUNCTION(BlueprintCallable, Category = "BioShock|Bathysphere")
	void SetUnlocked(bool bInUnlocked) { bUnlocked = bInUnlocked; }

	UFUNCTION(BlueprintCallable, Category = "BioShock|Bathysphere")
	bool TryTravelForOverlappingPlayer();

	static AShockBathysphereStation* FindByMapId(UWorld* World, FName MapId);

private:
	UFUNCTION()
	void OnTriggerBeginOverlap(
		UPrimitiveComponent* OverlappedComponent,
		AActor* OtherActor,
		UPrimitiveComponent* OtherComp,
		int32 OtherBodyIndex,
		bool bFromSweep,
		const FHitResult& SweepResult);

	UFUNCTION()
	void OnTriggerEndOverlap(
		UPrimitiveComponent* OverlappedComponent,
		AActor* OtherActor,
		UPrimitiveComponent* OtherComp,
		int32 OtherBodyIndex);

protected:
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "BioShock|Bathysphere")
	TObjectPtr<UBoxComponent> Trigger;

	UPROPERTY()
	TWeakObjectPtr<class AShockPlayer> OverlappingPlayer;
};
