#pragma once

#include "GameFramework/Actor.h"
#include "ShockConsumablePickup.generated.h"

class USphereComponent;
class AShockPlayer;

UENUM(BlueprintType)
enum class EShockPickupKind : uint8
{
	FirstAidKit UMETA(DisplayName="First Aid Kit"),
	EveHypo UMETA(DisplayName="EVE Hypo"),
	Money UMETA(DisplayName="Money"),
	Ammo UMETA(DisplayName="Ammo"),
};

/** World pickup for first-aid kits, EVE hypos, money, and ammo reserve grants. */
UCLASS()
class BIOSHOCKRUNTIME_API AShockConsumablePickup : public AActor
{
	GENERATED_BODY()

public:
	AShockConsumablePickup();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	TObjectPtr<USphereComponent> Collision;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Pickup")
	EShockPickupKind PickupKind = EShockPickupKind::FirstAidKit;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Pickup")
	int32 Amount = 1;

	/** When PickupKind is Ammo, grant to equipped weapon if None. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Pickup")
	FName WeaponDefName;

	/** Headless verify: apply pickup effect without overlap geometry. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Pickup")
	bool PickupForVerify(AShockPlayer* Player);

	UFUNCTION(BlueprintCallable, Category="BioShock|Pickup")
	void ConfigureForVerify(uint8 Kind, int32 InAmount, FName InWeaponDefName = NAME_None);

private:
	void ApplyPickup(AShockPlayer* Player);
	void DestroyAfterPickup();

	UFUNCTION()
	void OnOverlap(
		UPrimitiveComponent* OverlappedComponent,
		AActor* OtherActor,
		UPrimitiveComponent* OtherComp,
		int32 OtherBodyIndex,
		bool bFromSweep,
		const FHitResult& SweepResult);
};
