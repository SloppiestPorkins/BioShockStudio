#include "ShockPawn.h"

#include "BaseShockAI.h"
#include "EngineUtils.h"
#include "Engine/World.h"
#include "GameFramework/CharacterMovementComponent.h"

AShockPawn::AShockPawn()
{
	SchemaClassName = TEXT("ShockPawn");
	bUseControllerRotationYaw = false;
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
	EnsureHealthInitialized();
	if (bIsDead || bInvincible || Damage <= 0.0f)
	{
		return CurrentHealth;
	}
	CurrentHealth = FMath::Max(0.0f, CurrentHealth - Damage);
	if (CurrentHealth <= 0.0f)
	{
		bIsDead = true;
	}
	return CurrentHealth;
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
