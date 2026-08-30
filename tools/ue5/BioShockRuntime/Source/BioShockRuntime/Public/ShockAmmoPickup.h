#pragma once

#include "GameFramework/Actor.h"
#include "ShockAmmoPickup.generated.h"

class USphereComponent;
class AShockPlayer;

/** Playable-slice ammo pickup: overlap adds rounds to the equipped weapon reserve pool. */
UCLASS()
class BIOSHOCKRUNTIME_API AShockAmmoPickup : public AActor
{
	GENERATED_BODY()

public:
	AShockAmmoPickup();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	TObjectPtr<USphereComponent> Collision;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Ammo")
	int32 PickupAmount = 60;

	UFUNCTION(BlueprintCallable, Category="BioShock|Ammo")
	void TryGrantOverlappingPlayer();

private:
	void GrantToPlayer(AShockPlayer* Player);

	UFUNCTION()
	void OnOverlap(
		UPrimitiveComponent* OverlappedComponent,
		AActor* OtherActor,
		UPrimitiveComponent* OtherComp,
		int32 OtherBodyIndex,
		bool bFromSweep,
		const FHitResult& SweepResult);
};
