#pragma once

#include "GameFramework/Actor.h"
#include "ShockProjectile.generated.h"

class USphereComponent;
class UProjectileMovementComponent;

/**
 * Minimal stand-in for ShockGame explosive projectiles (FragGrenadeProjectile, etc.).
 * Sphere collision + movement; radial or direct damage on impact.
 */
UCLASS()
class BIOSHOCKRUNTIME_API AShockProjectile : public AActor
{
	GENERATED_BODY()

public:
	AShockProjectile();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	TObjectPtr<USphereComponent> CollisionSphere;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	TObjectPtr<UProjectileMovementComponent> Movement;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock")
	float InitialSpeed = 2500.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock")
	float Damage = 30.0f;

	/** 0 = direct hit only; >0 = ApplyRadialDamage at impact. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock")
	float ImpactRadius = 0.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock")
	float LifeSeconds = 10.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName SourceWeaponName;

	UFUNCTION(BlueprintCallable, Category="BioShock|Weapon")
	void ConfigureFromWeapon(
		FName InWeaponName,
		float InDamage,
		float InImpactRadius,
		float InInitialSpeed,
		float InLifeSeconds,
		AActor* InInstigator,
		const FVector& LaunchDirection);

	/** Headless verify: advance movement and collision without real-time wait. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Weapon")
	void AdvanceForVerify(float DeltaSeconds);

	UFUNCTION(BlueprintCallable, Category="BioShock|Weapon")
	bool HasImpactedForVerify() const { return bHasImpacted; }

private:
	UFUNCTION()
	void OnProjectileHit(
		UPrimitiveComponent* HitComponent,
		AActor* OtherActor,
		UPrimitiveComponent* OtherComp,
		FVector NormalImpulse,
		const FHitResult& Hit);

	void Detonate(const FVector& ImpactPoint, bool bDirectHit, const FHitResult* WorldHit);
	void ExpireLifetime(float DeltaSeconds);

	UPROPERTY(Transient)
	TWeakObjectPtr<AActor> DamageInstigator;

	float RemainingLife = 0.0f;
	bool bHasImpacted = false;
};
