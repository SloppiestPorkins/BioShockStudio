#pragma once

#include "GameFramework/Actor.h"
#include "ShockVitaChamber.generated.h"

class AShockPlayer;
class UBoxComponent;
class UPointLightComponent;
class UStaticMesh;
class UStaticMeshComponent;

/**
 * Runtime representation of ShockGame.BaseResurrectionStation.
 *
 * The shipped actor's PlayerStart bone is not retained by the level's static-mesh export, so the
 * slice uses an explicit local offset just outside the machine. See docs/research/vita-chamber.md.
 */
UCLASS()
class BIOSHOCKRUNTIME_API AShockVitaChamber : public AActor
{
	GENERATED_BODY()

public:
	AShockVitaChamber();

	virtual void BeginPlay() override;
	virtual void Tick(float DeltaSeconds) override;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|VitaChamber")
	TObjectPtr<UStaticMeshComponent> StationMesh;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|VitaChamber")
	TObjectPtr<UBoxComponent> ActivationVolume;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|VitaChamber")
	TObjectPtr<UPointLightComponent> ChamberGlow;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|VitaChamber")
	FName ScriptLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|VitaChamber")
	FString SourceKey;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|VitaChamber")
	bool bActive = true;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|VitaChamber")
	bool bAvailable = true;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|VitaChamber")
	FVector PlayerStartOffset = FVector(190.0f, 0.0f, 88.0f);

	UFUNCTION(BlueprintCallable, Category="BioShock|VitaChamber")
	void ConfigureIdentity(FName InLabel, const FString& InSourceKey);

	UFUNCTION(BlueprintCallable, Category="BioShock|VitaChamber")
	void SetStationMesh(UStaticMesh* InMesh);

	UFUNCTION(BlueprintCallable, Category="BioShock|VitaChamber")
	void SetActive(bool bInActive);

	UFUNCTION(BlueprintCallable, Category="BioShock|VitaChamber")
	void SetAvailable(bool bInAvailable);

	UFUNCTION(BlueprintPure, Category="BioShock|VitaChamber")
	bool CanResurrect() const { return bActive && bAvailable; }

	UFUNCTION(BlueprintPure, Category="BioShock|VitaChamber")
	FTransform GetPlayerStartTransform() const;

	/** ResurrectedPlayer effect hook: authored event first, located w1 cue as fallback, plus glow. */
	UFUNCTION(BlueprintCallable, Category="BioShock|VitaChamber")
	void PlayMaterialiseEffects();

	static AShockVitaChamber* FindNearestActive(UWorld* World, const FVector& From);

private:
	UFUNCTION()
	void OnActivationVolumeBeginOverlap(
		UPrimitiveComponent* OverlappedComponent,
		AActor* OtherActor,
		UPrimitiveComponent* OtherComponent,
		int32 OtherBodyIndex,
		bool bFromSweep,
		const FHitResult& SweepResult);

	void RefreshActiveAppearance();
	float MaterialisePulseRemaining = 0.0f;
};
