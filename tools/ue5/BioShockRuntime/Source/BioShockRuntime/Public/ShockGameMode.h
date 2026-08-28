#pragma once

#include "GameFramework/GameModeBase.h"
#include "ShockGameMode.generated.h"

class ABaseShockAI;
class AShockPlayer;

UCLASS()
class BIOSHOCKRUNTIME_API AShockGameMode : public AGameModeBase
{
	GENERATED_BODY()

public:
	AShockGameMode();

	virtual void PostLogin(APlayerController* NewPlayer) override;

	virtual AActor* ChoosePlayerStart_Implementation(AController* Player) override;

private:
	void SnapPawnToStart(APawn* Pawn, AActor* Start);
	void EquipStarterWeapon(AShockPlayer* Player);
	ABaseShockAI* SpawnSliceEnemy(AShockPlayer* Player, AActor* StartSpot);
	void VerifySliceFire(AShockPlayer* Player, ABaseShockAI* Enemy);
};
