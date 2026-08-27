#include "ShockGameMode.h"
#include "ShockPlayer.h"

#include "EngineUtils.h"
#include "GameFramework/PlayerController.h"
#include "GameFramework/PlayerStart.h"
#include "HAL/PlatformMisc.h"
#include "Misc/CommandLine.h"

AShockGameMode::AShockGameMode()
{
	DefaultPawnClass = AShockPlayer::StaticClass();
}

AActor* AShockGameMode::ChoosePlayerStart_Implementation(AController* Player)
{
	if (UWorld* World = GetWorld())
	{
		for (TActorIterator<APlayerStart> It(World); It; ++It)
		{
			for (const FName& Tag : It->Tags)
			{
				if (Tag.ToString().StartsWith(TEXT("BioShockPossess=")))
				{
					UE_LOG(
						LogTemp,
						Display,
						TEXT("BIOSHOCK_CHOOSE_START tagged label=%s loc=%s"),
						*It->GetActorLabel(),
						*It->GetActorLocation().ToString());
					return *It;
				}
			}
		}
		for (TActorIterator<APlayerStart> It(World); It; ++It)
		{
			const FString Label = It->GetActorLabel();
			if (Label.Equals(TEXT("MedicalStart")) || Label.Equals(TEXT("BioShock_MedicalStart")))
			{
				UE_LOG(
					LogTemp,
					Display,
					TEXT("BIOSHOCK_CHOOSE_START label=%s loc=%s"),
					*Label,
					*It->GetActorLocation().ToString());
				return *It;
			}
		}
		UE_LOG(LogTemp, Warning, TEXT("BIOSHOCK_CHOOSE_START fallback to engine default"));
	}
	return Super::ChoosePlayerStart_Implementation(Player);
}

void AShockGameMode::PostLogin(APlayerController* NewPlayer)
{
	Super::PostLogin(NewPlayer);

	if (NewPlayer && NewPlayer->GetPawn())
	{
		if (AActor* Start = ChoosePlayerStart_Implementation(NewPlayer))
		{
			APawn* Pawn = NewPlayer->GetPawn();
			Pawn->SetActorLocationAndRotation(
				Start->GetActorLocation(),
				Start->GetActorRotation(),
				false,
				nullptr,
				ETeleportType::TeleportPhysics);
		}
	}

	if (!FParse::Param(FCommandLine::Get(), TEXT("bioshockverifypossess")))
	{
		return;
	}

	APawn* Pawn = NewPlayer ? NewPlayer->GetPawn() : nullptr;
	if (!Pawn)
	{
		UE_LOG(LogTemp, Error, TEXT("BIOSHOCK_POSSESS_FAIL reason=no_pawn"));
	}
	else
	{
		const FVector Loc = Pawn->GetActorLocation();
		const bool bPlayable = Cast<AShockPlayer>(Pawn) && Cast<AShockPlayer>(Pawn)->IsPlayableInputEnabled();
		UE_LOG(
			LogTemp,
			Display,
			TEXT("BIOSHOCK_POSSESS_OK class=%s x=%.2f y=%.2f z=%.2f playable=%d"),
			*Pawn->GetClass()->GetName(),
			Loc.X,
			Loc.Y,
			Loc.Z,
			bPlayable ? 1 : 0);
	}

	FGenericPlatformMisc::RequestExit(false);
}
