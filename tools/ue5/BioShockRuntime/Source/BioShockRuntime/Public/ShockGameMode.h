#pragma once

#include "GameFramework/GameModeBase.h"
#include "ShockGameMode.generated.h"

UCLASS()
class BIOSHOCKRUNTIME_API AShockGameMode : public AGameModeBase
{
	GENERATED_BODY()

public:
	AShockGameMode();

	virtual void PostLogin(APlayerController* NewPlayer) override;

	virtual AActor* ChoosePlayerStart_Implementation(AController* Player) override;
};
