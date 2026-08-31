#pragma once

#include "ShockWeapon.h"
#include "ShockResearchCamera.generated.h"

class ABaseShockAI;
class AShockPlayer;

/**
 * UnrealScript `ResearchCamera` (holster slot 7). Slice: photograph live AI for per-archetype
 * research points; no film inventory, pause UI, or flash overlay yet.
 */
UCLASS()
class BIOSHOCKRUNTIME_API AShockResearchCamera : public AShockWeapon
{
	GENERATED_BODY()

public:
	AShockResearchCamera();

	/** PLAUSIBLE — UC awards integer PhotoScore.TotalScore (~0–100); slice scales by this float. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|ResearchCamera")
	float BasePhotoPoints = 100.0f;

	/** PLAUSIBLE — ResearchCamera.uc BaseFireRate=1.5; also per-target photo cooldown. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|ResearchCamera")
	float PhotoCooldownSeconds = 2.0f;

	/** PLAUSIBLE — half-angle of the aim cone (degrees). */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|ResearchCamera")
	float PhotoConeHalfAngleDeg = 25.0f;

	/** PLAUSIBLE — max distance to score a subject. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|ResearchCamera")
	float MaxPhotoRange = 3000.0f;

	UFUNCTION(BlueprintPure, Category="BioShock|ResearchCamera")
	float GetLastPhotoScoreForVerify() const { return LastPhotoScore; }

	UFUNCTION(BlueprintPure, Category="BioShock|ResearchCamera")
	float GetLastPhotoPointsForVerify() const { return LastPhotoPoints; }

	UFUNCTION(BlueprintCallable, Category="BioShock|ResearchCamera")
	void ClearPhotoCooldownForVerify();

	UFUNCTION(BlueprintCallable, Category="BioShock|ResearchCamera")
	void AdvancePhotoCooldownForVerify(float DeltaSeconds);

	virtual bool FireAt(AActor* InstigatorActor, FVector Start, FVector Direction) override;

private:
	ABaseShockAI* FindBestPhotoSubject(
		UWorld* World,
		AActor* InstigatorActor,
		const FVector& Start,
		const FVector& NormDir) const;

	float ComputePhotoScore(
		const FVector& Start,
		const FVector& NormDir,
		const ABaseShockAI* Target) const;

	bool HasLineOfSightTo(AActor* InstigatorActor, const FVector& Start, const ABaseShockAI* Target) const;

	float LastPhotoScore = 0.0f;
	float LastPhotoPoints = 0.0f;
	double LastGlobalPhotoWorldSeconds = -1.0;
	TMap<TWeakObjectPtr<ABaseShockAI>, double> LastPhotoTimeByTarget;
};
