#include "ShockSecurityCamera.h"

#include "BaseShockAI.h"
#include "ShockPawn.h"
#include "ShockPlayer.h"
#include "ShockSecuritySubsystem.h"
#include "Components/SpotLightComponent.h"
#include "Engine/World.h"
#include "EngineUtils.h"

AShockSecurityCamera::AShockSecurityCamera()
{
	Allegiance = EShockDeviceAllegiance::Hostile;
	DetectionHalfAngleDeg = 90.0f;

	Spotlight = CreateDefaultSubobject<USpotLightComponent>(TEXT("Spotlight"));
	if (Spotlight)
	{
		Spotlight->SetupAttachment(RootMesh);
		Spotlight->SetRelativeLocation(FVector(40.0f, 0.0f, 20.0f));
		Spotlight->SetInnerConeAngle(12.0f);
		Spotlight->SetOuterConeAngle(28.0f);
		Spotlight->SetIntensity(3000.0f);
		Spotlight->SetAttenuationRadius(2500.0f);
		Spotlight->SetVisibility(false);
	}
}

void AShockSecurityCamera::SetSpotlightEnabled(bool bEnabled)
{
	bSpotlightEnabled = bEnabled;
	if (Spotlight)
	{
		Spotlight->SetVisibility(bEnabled);
	}
}

void AShockSecurityCamera::ResetAlertState()
{
	AlertBuildupSeconds = 0.0f;
	bAlertTriggered = false;
}

AShockPawn* AShockSecurityCamera::FindBestOpposingTarget() const
{
	UWorld* World = GetWorld();
	if (!World)
	{
		return nullptr;
	}

	AShockPawn* Best = nullptr;
	float BestDistSq = MAX_FLT;
	const FVector Origin = GetActorLocation();

	for (TActorIterator<AShockPawn> It(World); It; ++It)
	{
		AShockPawn* Pawn = *It;
		if (!Pawn || !IsOpposingSide(Pawn) || !CanDetectActor(Pawn))
		{
			continue;
		}

		const float DistSq = FVector::DistSquared(Origin, Pawn->GetActorLocation());
		if (DistSq < BestDistSq)
		{
			BestDistSq = DistSq;
			Best = Pawn;
		}
	}
	return Best;
}

void AShockSecurityCamera::RaiseAlert(AShockPawn* Target)
{
	if (!Target || bAlertTriggered)
	{
		return;
	}

	bAlertTriggered = true;
	const FName Label = DeviceLabel.IsNone() ? GetFName() : DeviceLabel;
	UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_CAMERA_ALERT label=%s"), *Label.ToString());

	if (Allegiance == EShockDeviceAllegiance::Hostile)
	{
		if (UWorld* World = GetWorld())
		{
			if (UShockSecuritySubsystem* Security = UShockSecuritySubsystem::Get(World))
			{
				Security->OnCameraAlert(this);
			}
		}
	}
	// Friendly hacked cameras alert on splicers only — no player alarm or bot spawn in this slice.
}

void AShockSecurityCamera::TickDevice(float DeltaSeconds)
{
	if (!IsDeviceOperational())
	{
		return;
	}

	if (AShockPawn* Target = FindBestOpposingTarget())
	{
		AlertBuildupSeconds += DeltaSeconds;
		if (AlertBuildupSeconds >= AlertThreshold)
		{
			RaiseAlert(Target);
		}
	}
	else
	{
		AlertBuildupSeconds = FMath::Max(0.0f, AlertBuildupSeconds - AlertDecayPerSecond * DeltaSeconds);
		if (AlertBuildupSeconds <= KINDA_SMALL_NUMBER)
		{
			bAlertTriggered = false;
		}
	}
}
