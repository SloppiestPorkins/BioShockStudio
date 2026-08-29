#pragma once

#include "GameFramework/GameModeBase.h"
#include "ShockMenuGameMode.generated.h"

class UUserWidget;

/** Front-end GameMode: UI-only input, no HUD/pawn, shows the main menu widget. */
UCLASS()
class BIOSHOCKRUNTIME_API AShockMenuGameMode : public AGameModeBase
{
	GENERATED_BODY()

public:
	AShockMenuGameMode();

	virtual void PostLogin(APlayerController* NewPlayer) override;

	/** Widget class to show (defaults to UShockMainMenuWidget; setup may point at WBP_MainMenu). */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Menu")
	TSubclassOf<UUserWidget> MenuWidgetClass;

protected:
	void ShowMainMenu(APlayerController* Player);

	UPROPERTY(Transient)
	TObjectPtr<UUserWidget> ActiveMenuWidget = nullptr;
};
