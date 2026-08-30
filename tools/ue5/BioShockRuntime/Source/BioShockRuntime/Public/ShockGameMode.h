#pragma once

#include "GameFramework/GameModeBase.h"
#include "ShockGameMode.generated.h"

class ABaseShockAI;
class AShockPlayer;
class UShockDeathRespawnHandler;

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

	UFUNCTION(BlueprintCallable, Category="BioShock|Death")
	void BindPlayerDeathHandling(AShockPlayer* Player, AActor* RespawnStart);

	UFUNCTION(BlueprintPure, Category="BioShock|Death")
	bool IsRespawnPending() const;

	/** Headless verify: advance the respawn timer without waiting for real time. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Death")
	void AdvanceRespawnForVerify(float DeltaSeconds);

private:
	void SnapPawnToStart(APawn* Pawn, AActor* Start);
	void EquipStarterWeapon(AShockPlayer* Player);
	ABaseShockAI* SpawnSliceEnemy(AShockPlayer* Player, AActor* StartSpot);
	void VerifySliceFire(AShockPlayer* Player, ABaseShockAI* Enemy);
	UShockDeathRespawnHandler* EnsureDeathHandler();

	UPROPERTY()
	TObjectPtr<UShockDeathRespawnHandler> DeathHandler;
};
