#include "ShockInPlayerViewTrigger.h"

#include "Components/SceneComponent.h"
#include "EngineUtils.h"
#include "Engine/World.h"
#include "GameFramework/Controller.h"
#include "ShockPlayer.h"
#include "ShockScriptSubsystem.h"

AShockInPlayerViewTrigger::AShockInPlayerViewTrigger()
{
	PrimaryActorTick.bCanEverTick = true;
	// 14 instances in Medical, a plain FOV+LOS check each -- a few times a second is plenty
	// responsive for a narrative/tutorial beat and costs nothing meaningful.
	PrimaryActorTick.TickInterval = 0.25f;

	Root = CreateDefaultSubobject<USceneComponent>(TEXT("Root"));
	SetRootComponent(Root);

	SetActorEnableCollision(false);
}

void AShockInPlayerViewTrigger::Configure(FName InLabel, bool bInTriggerWhenNotSeen, float InMinimumDistance)
{
	TriggerLabel = InLabel;
	bTriggerWhenNotSeen = bInTriggerWhenNotSeen;
	MinimumDistance = InMinimumDistance;
}

bool AShockInPlayerViewTrigger::IsCurrentlyInPlayerView() const
{
	UWorld* World = GetWorld();
	if (!World)
	{
		return false;
	}
	// TActorIterator<AShockPlayer>, not UGameplayStatics::GetPlayerPawn: this plugin's own
	// convention for "find the player" (BaseShockAI::TryAcquireTargetFromPerception,
	// ShockAmmoPickup, ShockSecurityBot, ...) -- and the only one that finds a spawned AShockPlayer
	// in a headless verify world, which never runs GameMode/PlayerController possession.
	AShockPlayer* PlayerPawn = nullptr;
	for (TActorIterator<AShockPlayer> It(World); It; ++It)
	{
		PlayerPawn = *It;
		break;
	}
	if (!PlayerPawn)
	{
		return false;
	}
	AController* PC = PlayerPawn->GetController();
	const FVector EyeLoc = PlayerPawn->GetPawnViewLocation();
	const FVector EyeForward = PC ? PC->GetControlRotation().Vector() : PlayerPawn->GetActorForwardVector();

	const FVector ToTarget = GetActorLocation() - EyeLoc;
	const float Dist = ToTarget.Size();
	if (Dist <= KINDA_SMALL_NUMBER)
	{
		return true;
	}
	if (MinimumDistance > 0.0f && Dist > MinimumDistance)
	{
		return false;
	}

	// PLAUSIBLE 60-degree half-angle view cone -- see class comment.
	static const float ConeCos = FMath::Cos(FMath::DegreesToRadians(60.0f));
	const float CenterDot = FVector::DotProduct(EyeForward, ToTarget / Dist);
	if (CenterDot < ConeCos)
	{
		return false;
	}

	FHitResult Hit;
	FCollisionQueryParams Params(SCENE_QUERY_STAT(ShockInPlayerViewTriggerLoS), false, this);
	Params.AddIgnoredActor(this);
	Params.AddIgnoredActor(PlayerPawn);
	FCollisionObjectQueryParams ObjectParams;
	ObjectParams.AddObjectTypesToQuery(ECC_WorldStatic);
	ObjectParams.AddObjectTypesToQuery(ECC_WorldDynamic);
	if (World->LineTraceSingleByObjectType(Hit, EyeLoc, GetActorLocation(), ObjectParams, Params))
	{
		return false; // something opaque sits between the player and this point
	}
	return true;
}

void AShockInPlayerViewTrigger::Fire()
{
	bHasFired = true;
	if (UShockScriptSubsystem* Sub = UShockScriptSubsystem::Get(GetWorld()))
	{
		const FString Src = TriggerLabel.ToString();
		if (!Src.IsEmpty())
		{
			Sub->DispatchMessageLogged(FName(TEXT("MessageInPlayerView")), Src);
		}
	}
}

bool AShockInPlayerViewTrigger::EvaluateOnce()
{
	if (!bTriggerEnabled || bHasFired)
	{
		return false;
	}
	const bool bInView = IsCurrentlyInPlayerView();
	if (!bTriggerWhenNotSeen)
	{
		if (bInView)
		{
			Fire();
			return true;
		}
		return false;
	}

	if (bInView)
	{
		bHasEverBeenSeen = true;
		return false;
	}
	if (bHasEverBeenSeen)
	{
		Fire();
		return true;
	}
	return false;
}

void AShockInPlayerViewTrigger::Tick(float DeltaSeconds)
{
	Super::Tick(DeltaSeconds);
	EvaluateOnce();
}
