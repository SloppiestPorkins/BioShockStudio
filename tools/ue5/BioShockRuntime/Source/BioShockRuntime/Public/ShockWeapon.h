#pragma once

#include "GameFramework/Actor.h"
#include "ShockWeapon.generated.h"

class USkeletalMeshComponent;

/** UnrealScript class `Weapon` (super `Holdable`). Mesh and firing are not in this slice. */
UCLASS()
class BIOSHOCKRUNTIME_API AShockWeapon : public AActor
{
	GENERATED_BODY()

public:
	AShockWeapon();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	TObjectPtr<USkeletalMeshComponent> Mesh;
};
