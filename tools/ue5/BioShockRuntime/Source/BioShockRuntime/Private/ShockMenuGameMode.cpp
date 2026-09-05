#include "ShockMenuGameMode.h"
#include "ShockMainMenuWidget.h"

#include "Blueprint/UserWidget.h"
#include "Engine/TextureRenderTarget2D.h"
#include "GameFramework/HUD.h"
#include "GameFramework/PlayerController.h"
#include "Kismet/KismetRenderingLibrary.h"
#include "Misc/CommandLine.h"
#include "Misc/Parse.h"
#include "Misc/Paths.h"
#include "RenderingThread.h"
#include "Slate/WidgetRenderer.h"
#include "TimerManager.h"

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

	// -bioshockmenushot=<path>: render the menu widget to a PNG after a settle delay, then quit.
	// The screenshot harness on AShockGameMode can't reach here (menu map runs this game mode),
	// and a SceneCapture never sees the Slate layer -- so render the widget directly.
	FString ShotPath;
	if (FParse::Value(FCommandLine::Get(), TEXT("bioshockmenushot="), ShotPath) && !ShotPath.IsEmpty())
	{
		FTimerHandle Handle;
		TWeakObjectPtr<AShockMenuGameMode> WeakThis(this);
		const FString CapturedPath = ShotPath;
		Player->GetWorldTimerManager().SetTimer(Handle, FTimerDelegate::CreateLambda([WeakThis, CapturedPath]()
		{
			AShockMenuGameMode* Self = WeakThis.Get();
			if (!Self || !Self->ActiveMenuWidget || !Self->GetWorld())
			{
				FGenericPlatformMisc::RequestExit(false);
				return;
			}
			int32 W = 1280, H = 720;
			FParse::Value(FCommandLine::Get(), TEXT("bioshockshotwidth="), W);
			FParse::Value(FCommandLine::Get(), TEXT("bioshockshotheight="), H);
			FWidgetRenderer Renderer(/*bUseGammaCorrection*/ true);
			UTextureRenderTarget2D* RT = UKismetRenderingLibrary::CreateRenderTarget2D(
				Self->GetWorld(), W, H, RTF_RGBA8);
			RT->ClearColor = FLinearColor(0.05f, 0.05f, 0.06f, 1.0f);
			Renderer.DrawWidget(RT, Self->ActiveMenuWidget->TakeWidget(), FVector2D(W, H), 0.0f);
			FlushRenderingCommands();
			UKismetRenderingLibrary::ExportRenderTarget(
				Self->GetWorld(), RT, FPaths::GetPath(CapturedPath), FPaths::GetCleanFilename(CapturedPath));
			UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_MENU_SHOT path=%s"), *CapturedPath);
			FGenericPlatformMisc::RequestExit(false);
		}), 6.0f, false);
	}
}
