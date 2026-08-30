#pragma once

#include "UObject/Object.h"
#include "ShockDeathRespawnHandler.generated.h"

class AActor;
class AShockPlayer;
class UShockDeathOverlayWidget;
class UWorld;

/** Vita-Chamber-style respawn slice owned by AShockGameMode; UObject so headless verify can NewObject it. */
UCLASS()
class BIOSHOCKRUNTIME_API UShockDeathRespawnHandler : public UObject
{
	GENERATED_BODY()

public:
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Death")
	float RespawnDelaySeconds = 3.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Death")
	bool bReloadLevelOnDeath = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Death")
	void Initialize(UWorld* InWorld, AShockPlayer* Player, AActor* RespawnStart);

	UFUNCTION(BlueprintPure, Category="BioShock|Death")
	bool IsRespawnPending() const { return bRespawnPending; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Death")
	void AdvanceRespawnForVerify(float DeltaSeconds);

	UFUNCTION()
	void HandlePlayerDied(AShockPlayer* Player);

private:
	void ShowDeathOverlay(AShockPlayer* Player);
	void FadeDeathOverlay();
	void PerformRespawn();
	void SnapPawnToStart(APawn* Pawn, AActor* Start) const;

	UPROPERTY()
	TWeakObjectPtr<UWorld> World;

	UPROPERTY()
	TWeakObjectPtr<AShockPlayer> BoundPlayer;

	UPROPERTY()
	TWeakObjectPtr<AActor> RespawnStartSpot;

	UPROPERTY()
	TWeakObjectPtr<AShockPlayer> PendingRespawnPlayer;

	UPROPERTY()
	TObjectPtr<UShockDeathOverlayWidget> DeathOverlay;

	FTimerHandle RespawnTimerHandle;
	float RespawnCountdown = 0.0f;
	bool bRespawnPending = false;
};
