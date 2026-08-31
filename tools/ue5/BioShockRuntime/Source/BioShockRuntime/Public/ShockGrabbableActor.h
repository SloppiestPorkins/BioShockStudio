#pragma once

#include "GameFramework/Actor.h"
#include "ShockGrabbableActor.generated.h"

class UStaticMeshComponent;

/** Telekinesis verify / slice stand-in for physics props (PLAUSIBLE holdable). */
UCLASS()
class BIOSHOCKRUNTIME_API AShockGrabbableActor : public AActor
{
	GENERATED_BODY()

public:
	AShockGrabbableActor();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "BioShock|Grabbable")
	TObjectPtr<UStaticMeshComponent> Mesh;

	UFUNCTION(BlueprintPure, Category = "BioShock|Grabbable")
	bool IsPhysicsFrozenForVerify() const;
};
