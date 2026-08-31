#pragma once

#include "GameFramework/GameModeBase.h"
#include "TimerManager.h"
#include "ShockGameMode.generated.h"

class ABaseShockAI;
class AShockPlayer;
class UShockDeathRespawnHandler;
class UShockHudWidget;

UCLASS()
class BIOSHOCKRUNTIME_API AShockGameMode : public AGameModeBase
{
	GENERATED_BODY()

public:
	AShockGameMode();

	virtual void PostLogin(APlayerController* NewPlayer) override;

	virtual AActor* ChoosePlayerStart_Implementation(AController* Player) override;

	/** Vita-Chamber-style in-place reset after death (default). */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Death")
	float RespawnDelaySeconds = 3.0f;

	/** When true, reload the current map instead of in-place reset. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Death")
	bool bReloadLevelOnDeath = false;

	/** Off by default so possess / encounter verifies stay unchanged. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Slice")
	bool bEnableSliceTurret = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Death")
	void BindPlayerDeathHandling(AShockPlayer* Player, AActor* RespawnStart);

	UFUNCTION(BlueprintPure, Category="BioShock|Death")
	bool IsRespawnPending() const;

	/** Headless verify: advance the respawn timer without waiting for real time. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Death")
	void AdvanceRespawnForVerify(float DeltaSeconds);

	/** Headless verify: kick UNavigationSystemV1::Build on the editor world. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Nav", meta=(WorldContext="WorldContextObject"))
	static bool BuildNavigationForVerify(UObject* WorldContextObject);

	/** Headless verify: true when ProjectPointToNavigation succeeds for Point. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Nav", meta=(WorldContext="WorldContextObject"))
	static bool CanProjectPointToNavigation(UObject* WorldContextObject, FVector Point);

private:
	void SnapPawnToStart(APawn* Pawn, AActor* Start);
	void EquipStarterWeapon(AShockPlayer* Player);
	void SpawnSliceEncounter(AShockPlayer* Player, AActor* StartSpot);
	ABaseShockAI* SpawnOneSliceEnemy(
		AShockPlayer* Player,
		int32 Index,
		FName ArchetypeKey,
		const FVector& SpawnLoc,
		const FRotator& SpawnRot,
		bool bForceRangedWeapon);
	void SpawnSliceEnemyStaggered(
		AShockPlayer* Player,
		AActor* StartSpot,
		int32 Index,
		FVector SpawnLoc,
		FRotator SpawnRot,
		FName ArchetypeKey,
		bool bForceRangedWeapon);
	void VerifySliceEncounter(AShockPlayer* Player);
	void EnsureSliceNavigation(AShockPlayer* Player, AActor* StartSpot);
	void SpawnSliceAmmoPickup(AShockPlayer* Player, AActor* StartSpot, ABaseShockAI* Enemy);
	void SpawnSliceTurret(AShockPlayer* Player, AActor* StartSpot);
	void VerifySliceFire(AShockPlayer* Player, ABaseShockAI* Enemy);
	void EnsureHudForPlayer(APlayerController* PC);
	UShockDeathRespawnHandler* EnsureDeathHandler();

	FTimerHandle SliceEncounterSpawnTimer1;
	FTimerHandle SliceEncounterSpawnTimer2;
	FTimerHandle SliceEncounterVerifyTimer;

	UPROPERTY()
	TObjectPtr<UShockDeathRespawnHandler> DeathHandler;

	UPROPERTY()
	TObjectPtr<UShockHudWidget> PlayerHud;
};
