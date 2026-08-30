#include "ShockDeathRespawnHandler.h"

#include "ShockDeathOverlayWidget.h"
#include "ShockPlayer.h"

#include "CollisionQueryParams.h"
#include "Components/CapsuleComponent.h"
#include "Engine/World.h"
#include "GameFramework/Character.h"
#include "GameFramework/PlayerController.h"
#include "Kismet/GameplayStatics.h"
#include "TimerManager.h"

namespace
{
FRotator PlayableStartRotation(const AActor* Start)
{
	FRotator Look = Start ? Start->GetActorRotation() : FRotator::ZeroRotator;
	if (FMath::IsNearlyZero(Look.Yaw, 1.0f)
		&& FMath::IsNearlyEqual(FMath::Abs(Look.Pitch), 90.0f, 1.0f))
	{
		Look.Yaw = 90.0f;
	}
	Look.Pitch = 0.0f;
	Look.Roll = 0.0f;
	return Look;
}
}

void UShockDeathRespawnHandler::Initialize(UWorld* InWorld, AShockPlayer* Player, AActor* RespawnStart)
{
	World = InWorld;
	RespawnStartSpot = RespawnStart;
	if (!Player)
	{
		return;
	}
	if (BoundPlayer.IsValid())
	{
		BoundPlayer->OnPlayerDied.RemoveDynamic(this, &UShockDeathRespawnHandler::HandlePlayerDied);
	}
	BoundPlayer = Player;
	Player->OnPlayerDied.AddDynamic(this, &UShockDeathRespawnHandler::HandlePlayerDied);
}

void UShockDeathRespawnHandler::SnapPawnToStart(APawn* Pawn, AActor* Start) const
{
	if (!Pawn || !Start)
	{
		return;
	}

	UWorld* UseWorld = Pawn->GetWorld();
	FVector Loc = Start->GetActorLocation();
	const FRotator Rot = PlayableStartRotation(Start);

	if (ACharacter* Character = Cast<ACharacter>(Pawn))
	{
		const UCapsuleComponent* Capsule = Character->GetCapsuleComponent();
		const float HalfHeight = Capsule ? Capsule->GetScaledCapsuleHalfHeight() : 88.0f;
		if (UseWorld)
		{
			const FVector TraceStart = Loc + FVector(0.0f, 0.0f, 8.0f);
			const FVector TraceEnd = Loc - FVector(0.0f, 0.0f, HalfHeight + 40.0f);
			FHitResult Hit;
			FCollisionQueryParams Params(SCENE_QUERY_STAT(BioShockDeathRespawnSnap), false, Pawn);
			if (UseWorld->LineTraceSingleByChannel(Hit, TraceStart, TraceEnd, ECC_WorldStatic, Params)
				&& Hit.ImpactNormal.Z > 0.5f)
			{
				Loc.Z = Hit.Location.Z + HalfHeight + 2.0f;
			}
		}
	}

	Pawn->SetActorLocationAndRotation(Loc, Rot, false, nullptr, ETeleportType::TeleportPhysics);
}

void UShockDeathRespawnHandler::ShowDeathOverlay(AShockPlayer* Player)
{
	if (!Player)
	{
		return;
	}
	APlayerController* PC = Cast<APlayerController>(Player->GetController());
	if (!PC)
	{
		return;
	}
	if (!DeathOverlay)
	{
		DeathOverlay = CreateWidget<UShockDeathOverlayWidget>(PC, UShockDeathOverlayWidget::StaticClass());
	}
	if (DeathOverlay && !DeathOverlay->IsInViewport())
	{
		DeathOverlay->AddToViewport(100);
	}
	if (DeathOverlay)
	{
		DeathOverlay->ShowDeathMessage();
	}
}

void UShockDeathRespawnHandler::FadeDeathOverlay()
{
	if (DeathOverlay)
	{
		DeathOverlay->FadeOutBeforeRespawn();
		DeathOverlay = nullptr;
	}
}

void UShockDeathRespawnHandler::HandlePlayerDied(AShockPlayer* Player)
{
	if (!Player || bRespawnPending)
	{
		return;
	}

	PendingRespawnPlayer = Player;
	bRespawnPending = true;
	RespawnCountdown = RespawnDelaySeconds;
	ShowDeathOverlay(Player);

	if (bReloadLevelOnDeath)
	{
		const FString MapName = UGameplayStatics::GetCurrentLevelName(Player, true);
		UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_DEATH_RELOAD map=%s"), *MapName);
		UGameplayStatics::OpenLevel(Player, FName(*MapName));
		return;
	}

	UWorld* UseWorld = World.Get();
	if (!UseWorld)
	{
		UseWorld = Player->GetWorld();
	}
	if (!UseWorld)
	{
		return;
	}

	UseWorld->GetTimerManager().SetTimer(
		RespawnTimerHandle,
		this,
		&UShockDeathRespawnHandler::PerformRespawn,
		RespawnDelaySeconds,
		false);
}

void UShockDeathRespawnHandler::AdvanceRespawnForVerify(float DeltaSeconds)
{
	if (!bRespawnPending || bReloadLevelOnDeath)
	{
		return;
	}
	RespawnCountdown -= DeltaSeconds;
	if (RespawnCountdown > 0.0f)
	{
		return;
	}
	if (UWorld* UseWorld = World.Get())
	{
		UseWorld->GetTimerManager().ClearTimer(RespawnTimerHandle);
	}
	PerformRespawn();
}

void UShockDeathRespawnHandler::PerformRespawn()
{
	bRespawnPending = false;
	FadeDeathOverlay();

	AShockPlayer* Player = PendingRespawnPlayer.Get();
	PendingRespawnPlayer = nullptr;
	if (!Player)
	{
		return;
	}

	const float MaxHealth = Player->AuthoredMaxHealth > 0.0f
		? Player->AuthoredMaxHealth
		: (Player->AuthoredHealth > 0.0f ? Player->AuthoredHealth : 100.0f);
	Player->ResetForRespawn(MaxHealth);

	AActor* Start = RespawnStartSpot.Get();
	if (Start)
	{
		SnapPawnToStart(Player, Start);
		if (APlayerController* PC = Cast<APlayerController>(Player->GetController()))
		{
			PC->SetControlRotation(PlayableStartRotation(Start));
		}
	}

	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_RESPAWN_OK health=%.1f loc=%s"),
		Player->GetCurrentHealth(),
		*Player->GetActorLocation().ToString());
}
