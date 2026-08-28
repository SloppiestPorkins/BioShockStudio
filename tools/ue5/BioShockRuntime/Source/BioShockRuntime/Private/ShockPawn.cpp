#include "ShockPawn.h"

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
