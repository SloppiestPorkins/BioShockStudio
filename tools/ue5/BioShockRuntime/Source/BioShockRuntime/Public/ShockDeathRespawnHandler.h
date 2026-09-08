#pragma once

#include "UObject/Object.h"
#include "ShockDeathRespawnHandler.generated.h"

class AActor;
class AShockPlayer;
class AShockVitaChamber;
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

	/** BaseResurrectionStation.uc defaultproperties. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Death")
	float RestoredHealthFraction = 0.50f;

	/** ShockPlayer.uc EveBarPercentageToRestoreOnRessurection. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Death")
	float RestoredEveFloorFraction = 0.75f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Death")
	float InvulnerabilitySeconds = 2.0f;

	UFUNCTION(BlueprintCallable, Category="BioShock|Death")
	void Initialize(UWorld* InWorld, AShockPlayer* Player, AActor* RespawnStart);

	UFUNCTION(BlueprintPure, Category="BioShock|Death")
	bool IsRespawnPending() const { return bRespawnPending; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Death")
	void AdvanceRespawnForVerify(float DeltaSeconds);

	UFUNCTION(BlueprintPure, Category="BioShock|Death")
	AShockVitaChamber* GetLastSelectedChamber() const { return LastSelectedChamber.Get(); }

	UFUNCTION()
	void HandlePlayerDied(AShockPlayer* Player);

private:
	void ShowDeathOverlay(AShockPlayer* Player);
	void FadeDeathOverlay();
	void PerformRespawn();
	void EndRespawnInvulnerability();
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
	TWeakObjectPtr<AShockVitaChamber> LastSelectedChamber;

	UPROPERTY()
	TObjectPtr<UShockDeathOverlayWidget> DeathOverlay;

	FTimerHandle RespawnTimerHandle;
	FTimerHandle InvulnerabilityTimerHandle;
	float RespawnCountdown = 0.0f;
	bool bRespawnPending = false;
};
