#include "ShockPawn.h"

#include "BaseShockAI.h"
#include "ShockAudioLibrary.h"
#include "ShockDamageLibrary.h"
#include "Components/AudioComponent.h"
#include "EngineUtils.h"
#include "Engine/World.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "Materials/MaterialInterface.h"

AShockPawn::AShockPawn()
{
	SchemaClassName = TEXT("ShockPawn");
	bUseControllerRotationYaw = false;
	PrimaryActorTick.bCanEverTick = true;
}

void AShockPawn::Tick(float DeltaSeconds)
{
	Super::Tick(DeltaSeconds);
	TickFootstepAudio(DeltaSeconds);
}

FName AShockPawn::ResolveFootstepSurface() const
{
	UWorld* World = GetWorld();
	if (!World)
	{
		return TEXT("MVT_Default");
	}

	FHitResult Hit;
	FCollisionQueryParams Params(SCENE_QUERY_STAT(BioShockFootstepSurface), false, this);
	const FVector Start = GetActorLocation();
	const bool bHit = World->LineTraceSingleByChannel(
		Hit,
		Start,
		Start - FVector(0.0f, 0.0f, 160.0f),
		ECC_Visibility,
		Params);
	if (!bHit || !Hit.GetComponent())
	{
		return TEXT("MVT_Default");
	}

	FString MaterialName;
	if (UMaterialInterface* Material = Hit.GetComponent()->GetMaterial(0))
	{
		MaterialName = Material->GetName();
	}
	if (MaterialName.Contains(TEXT("water"), ESearchCase::IgnoreCase))
	{
		return TEXT("MVT_Water");
	}
	if (MaterialName.Contains(TEXT("metal"), ESearchCase::IgnoreCase)
		|| MaterialName.Contains(TEXT("grate"), ESearchCase::IgnoreCase))
	{
		return TEXT("MVT_ThickMetal");
	}
	if (MaterialName.Contains(TEXT("tile"), ESearchCase::IgnoreCase)
		|| MaterialName.Contains(TEXT("marble"), ESearchCase::IgnoreCase)
		|| MaterialName.Contains(TEXT("stone"), ESearchCase::IgnoreCase))
	{
		return TEXT("MVT_Stone");
	}
	return TEXT("MVT_Default");
}

void AShockPawn::TickFootstepAudio(float DeltaSeconds)
{
	if (DeltaSeconds <= 0.0f || bIsDead || !GetCharacterMovement()
		|| !GetCharacterMovement()->IsMovingOnGround())
	{
		return;
	}
	const FVector Velocity = GetVelocity();
	const float HorizontalSpeed = FVector(Velocity.X, Velocity.Y, 0.0f).Size();
	if (HorizontalSpeed < 20.0f)
	{
		FootstepTravel = 0.0f;
		return;
	}

	FootstepTravel += HorizontalSpeed * DeltaSeconds;
	const float StepDistance = HorizontalSpeed > 450.0f ? 150.0f : 190.0f;
	if (FootstepTravel < StepDistance)
	{
		return;
	}
	FootstepTravel = FMath::Fmod(FootstepTravel, StepDistance);

	const FName Surface = ResolveFootstepSurface();
	const FName BaseCue = IsPlayerControlled()
		? FName(TEXT("footstep_bootPlayer_step"))
		: FName(TEXT("footstep_dressShoe"));
	const FName SurfaceCue(*FString::Printf(
		TEXT("%s__%s"),
		*BaseCue.ToString(),
		*Surface.ToString()));
	FName PlayedCue = SurfaceCue;
	UAudioComponent* Component =
		UShockAudioLibrary::SpawnCueAtLocation(GetWorld(), SurfaceCue, GetActorLocation());
	if (!Component && Surface != FName(TEXT("MVT_Default")))
	{
		const FName DefaultCue(*FString::Printf(
			TEXT("%s__MVT_Default"),
			*BaseCue.ToString()));
		Component = UShockAudioLibrary::SpawnCueAtLocation(
			GetWorld(), DefaultCue, GetActorLocation());
		PlayedCue = DefaultCue;
	}
	if (Component)
	{
		++FootstepAudioCount;
		UE_LOG(
			LogTemp,
			Display,
			TEXT("BIOSHOCK_AUDIO footstep pawn=%s surface=%s sound=%s"),
			*GetName(),
			*Surface.ToString(),
			*PlayedCue.ToString());
	}
}

void AShockPawn::EnsureHealthInitialized()
{
	if (CurrentHealth > 0.0f)
	{
		return;
	}
	const float Seed = AuthoredMaxHealth > 0.0f ? AuthoredMaxHealth : AuthoredHealth;
	CurrentHealth = Seed > 0.0f ? Seed : 100.0f;
	bIsDead = false;
}

float AShockPawn::ApplyAuthoredDamage(float Damage)
{
	UShockDamageLibrary::ApplyDamage(this, Damage, nullptr, NAME_None);
	return CurrentHealth;
}

void AShockPawn::OnDeathFromDamage()
{
}

void AShockPawn::SetScriptedPhysicsDisabled(bool bDisable, bool bRootMotion)
{
	bPhysicsDisabled = bDisable;
	bRootMotionWhenPhysicsDisabled = bRootMotion;
	if (UCharacterMovementComponent* Move = GetCharacterMovement())
	{
		Move->SetMovementMode(bDisable ? MOVE_None : MOVE_Walking);
	}
}

TArray<AShockPawn*> AShockPawn::CollectLabeled(UWorld* World, FName Label)
{
	TArray<AShockPawn*> Out;
	if (!World || Label.IsNone())
	{
		return Out;
	}
	const FString Want = Label.ToString();
	for (TActorIterator<AShockPawn> It(World); It; ++It)
	{
		AShockPawn* Pawn = *It;
		if (!Pawn)
		{
			continue;
		}
		bool bMatch = false;
#if WITH_EDITOR
		bMatch = Pawn->GetActorLabel().Equals(Want, ESearchCase::CaseSensitive);
#endif
		if (!bMatch)
		{
			if (const ABaseShockAI* AI = Cast<ABaseShockAI>(Pawn))
			{
				bMatch = AI->GetScriptLabel().ToString().Equals(Want, ESearchCase::CaseSensitive);
			}
		}
		if (bMatch)
		{
			Out.Add(Pawn);
		}
	}
	return Out;
}
