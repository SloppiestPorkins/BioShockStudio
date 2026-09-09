#pragma once

#include "GameFramework/Actor.h"
#include "ShockPlasmidFx.generated.h"

class UNiagaraComponent;
class USceneComponent;
class UStaticMeshComponent;
class UWorld;

/**
 * Cheap, short-lived plasmid presentation actor. Every instance owns a Niagara component and a
 * small emissive mesh, so casts remain visible if the stand-in Niagara assets have not been
 * authored into the target project yet. The mesh is presentation only and never collides.
 */
UCLASS()
class BIOSHOCKRUNTIME_API AShockPlasmidFx : public AActor
{
	GENERATED_BODY()

public:
	AShockPlasmidFx();

	static AShockPlasmidFx* SpawnBurst(
		UWorld* World,
		const FString& SystemAssetPath,
		const FVector& WorldLocation,
		const FRotator& WorldRotation,
		const FLinearColor& Tint,
		float LifeSeconds,
		float Radius,
		USceneComponent* AttachParent = nullptr);

	static AShockPlasmidFx* SpawnBeam(
		UWorld* World,
		const FString& SystemAssetPath,
		const FVector& Start,
		const FVector& End,
		const FLinearColor& Tint,
		float LifeSeconds,
		float Radius = 2.0f);

	UFUNCTION(BlueprintPure, Category = "BioShock|Plasmid|FX")
	UNiagaraComponent* GetNiagaraComponentForVerify() const { return Niagara; }

	UFUNCTION(BlueprintPure, Category = "BioShock|Plasmid|FX")
	FString GetRequestedAssetPathForVerify() const { return RequestedAssetPath; }

	UFUNCTION(BlueprintPure, Category = "BioShock|Plasmid|FX")
	bool WasNiagaraAssetLoadedForVerify() const { return bNiagaraAssetLoaded; }

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "BioShock|Plasmid|FX")
	TObjectPtr<UNiagaraComponent> Niagara;

private:
	void ConfigureCommon(
		const FString& SystemAssetPath,
		const FLinearColor& Tint,
		float LifeSeconds);

	UPROPERTY()
	TObjectPtr<USceneComponent> SceneRoot;

	UPROPERTY()
	TObjectPtr<UStaticMeshComponent> OrbMesh;

	UPROPERTY()
	TObjectPtr<UStaticMeshComponent> BeamMesh;

	UPROPERTY()
	FString RequestedAssetPath;

	bool bNiagaraAssetLoaded = false;
};
