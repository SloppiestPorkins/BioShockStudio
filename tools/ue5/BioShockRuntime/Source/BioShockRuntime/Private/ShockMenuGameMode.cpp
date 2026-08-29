#include "ShockMenuGameMode.h"
#include "ShockMainMenuWidget.h"

#include "Blueprint/UserWidget.h"
#include "GameFramework/HUD.h"
#include "GameFramework/PlayerController.h"

AShockMenuGameMode::AShockMenuGameMode()
{
	DefaultPawnClass = nullptr;
	HUDClass = nullptr;
	MenuWidgetClass = UShockMainMenuWidget::StaticClass();
}

void AShockMenuGameMode::PostLogin(APlayerController* NewPlayer)
{
	Super::PostLogin(NewPlayer);
	ShowMainMenu(NewPlayer);
}

void AShockMenuGameMode::ShowMainMenu(APlayerController* Player)
{
	if (!Player || ActiveMenuWidget)
	{
		return;
	}

	TSubclassOf<UUserWidget> ClassToSpawn = MenuWidgetClass;
	if (!*ClassToSpawn)
	{
		ClassToSpawn = UShockMainMenuWidget::StaticClass();
	}

	// Prefer the setup-authored WidgetBlueprint when it exists (same C++ parent, designer-ready).
	if (UClass* WbpClass = LoadClass<UUserWidget>(
			nullptr, TEXT("/Game/BioShockUI/WBP_MainMenu.WBP_MainMenu_C")))
	{
		ClassToSpawn = WbpClass;
	}

	ActiveMenuWidget = CreateWidget<UUserWidget>(Player, ClassToSpawn);
	if (!ActiveMenuWidget)
	{
		UE_LOG(LogTemp, Error, TEXT("BIOSHOCK_MENU_FAIL reason=create_widget"));
		return;
	}

	ActiveMenuWidget->AddToViewport(0);

	Player->bShowMouseCursor = true;
	Player->bEnableClickEvents = true;
	Player->bEnableMouseOverEvents = true;

	FInputModeUIOnly InputMode;
	InputMode.SetLockMouseToViewportBehavior(EMouseLockMode::DoNotLock);
	InputMode.SetWidgetToFocus(ActiveMenuWidget->TakeWidget());
	Player->SetInputMode(InputMode);

	if (AHUD* HUD = Player->GetHUD())
	{
		HUD->bShowHUD = false;
	}

	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_MENU_OK widget=%s"),
		*ActiveMenuWidget->GetClass()->GetName());
}
