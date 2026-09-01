#include "ShockDamageLibrary.h"

#include "BaseShockAI.h"
#include "EngineUtils.h"
#include "GameFramework/Actor.h"
#include "ShockPawn.h"
#include "ShockPlayer.h"

AActor* UShockDamageLibrary::FindActorByLabel(UWorld* World, FName Label)
{
	if (!World || Label.IsNone())
	{
		return nullptr;
	}
	const FString Want = Label.ToString();
	for (TActorIterator<AActor> It(World); It; ++It)
	{
		AActor* Actor = *It;
		if (!Actor)
		{
			continue;
		}
#if WITH_EDITOR
		if (Actor->GetActorLabel().Equals(Want, ESearchCase::CaseSensitive))
		{
			return Actor;
		}
#endif
		if (const ABaseShockAI* AI = Cast<ABaseShockAI>(Actor))
		{
			if (AI->GetScriptLabel().ToString().Equals(Want, ESearchCase::CaseSensitive))
			{
				return Actor;
			}
		}
	}
	return nullptr;
}

AShockPlayer* UShockDamageLibrary::ResolvePlayerFrom(AActor* Source)
{
	for (AActor* Current = Source; Current; )
	{
		if (AShockPlayer* Player = Cast<AShockPlayer>(Current))
		{
			return Player;
		}

		AActor* Next = Current->GetInstigator();
		if (Next && Next != Current)
		{
			Current = Next;
			continue;
		}

		Next = Current->GetOwner();
		if (Next && Next != Current)
		{
			Current = Next;
			continue;
		}

		break;
	}
	return nullptr;
}

float UShockDamageLibrary::ApplyDamage(AActor* Target, float Amount, AActor* Instigator, FName DamageType)
{
	(void)DamageType;

	AShockPawn* Pawn = Cast<AShockPawn>(Target);
	if (!Pawn || Amount <= 0.0f)
	{
		return 0.0f;
	}

	Pawn->EnsureHealthInitialized();
	if (Pawn->IsDead() || Pawn->IsInvincible())
	{
		return 0.0f;
	}

	if (ABaseShockAI* AI = Cast<ABaseShockAI>(Pawn))
	{
		if (!AI->IsVulnerable())
		{
			return 0.0f;
		}
		if (AShockPlayer* Player = Cast<AShockPlayer>(Instigator))
		{
			AI->NotifyAggroFromPlayer(Player);
		}
	}

	float ScaledAmount = Amount;
	if (ABaseShockAI* TargetAI = Cast<ABaseShockAI>(Pawn))
	{
		if (TargetAI->GetFrozenSolidRemaining() > 0.0f)
		{
			ScaledAmount *= 3.0f; // PLAUSIBLE — shatter multiplier while frozen solid
			const FString AiName = TargetAI->GetScriptLabel().IsNone()
				? TargetAI->GetName()
				: TargetAI->GetScriptLabel().ToString();
			UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_SHATTER ai=%s"), *AiName);
		}
		if (!TargetAI->AITypeName.IsNone())
		{
			if (AShockPlayer* Player = ResolvePlayerFrom(Instigator))
			{
				ScaledAmount *= Player->GetResearchDamageMultiplier(TargetAI->AITypeName);
			}
		}
	}

	const float Before = Pawn->GetCurrentHealth();
	float Applied = FMath::Min(ScaledAmount, Before);

	if (const ABaseShockAI* AI = Cast<ABaseShockAI>(Pawn))
	{
		if (AI->CannotDie())
		{
			const float After = FMath::Max(1.0f, Before - Applied);
			Applied = Before - After;
			Pawn->CurrentHealth = After;
			if (Applied > 0.0f)
			{
				Cast<ABaseShockAI>(Pawn)->ReactToHit(Applied, Instigator);
			}
			return Applied;
		}
	}

	const bool bWasDead = Pawn->bIsDead;
	Pawn->CurrentHealth = FMath::Max(0.0f, Before - Applied);
	if (Pawn->CurrentHealth <= 0.0f)
	{
		Pawn->bIsDead = true;
	}
	if (!bWasDead && Pawn->bIsDead)
	{
		Pawn->OnDeathFromDamage();
	}
	else if (ABaseShockAI* AI = Cast<ABaseShockAI>(Pawn))
	{
		if (Applied > 0.0f && !Pawn->bIsDead)
		{
			AI->ReactToHit(Applied, Instigator);
		}
	}
	if (AShockPlayer* Player = Cast<AShockPlayer>(Pawn))
	{
		if (Applied > 0.0f && !Pawn->bIsDead)
		{
			Player->TryAutoFirstAidAfterDamage();
		}
	}
	return Applied;
}

int32 UShockDamageLibrary::ApplyRadialDamage(
	UWorld* World,
	FVector Origin,
	float OuterRadius,
	float Amount,
	AActor* Instigator,
	FName DamageType,
	float InnerRadius)
{
	if (!World || Amount <= 0.0f || OuterRadius <= 0.0f)
	{
		return 0;
	}

	const float Inner = FMath::Clamp(InnerRadius, 0.0f, OuterRadius);
	int32 HitCount = 0;

	for (TActorIterator<AShockPawn> It(World); It; ++It)
	{
		AShockPawn* Pawn = *It;
		if (!Pawn)
		{
			continue;
		}
		const float Dist = FVector::Dist(Origin, Pawn->GetActorLocation());
		if (Dist > OuterRadius)
		{
			continue;
		}

		float Falloff = 1.0f;
		if (OuterRadius > Inner && Dist > Inner)
		{
			Falloff = 1.0f - (Dist - Inner) / (OuterRadius - Inner);
		}
		const float Scaled = Amount * Falloff;
		if (UShockDamageLibrary::ApplyDamage(Pawn, Scaled, Instigator, DamageType) > 0.0f)
		{
			++HitCount;
		}
	}
	return HitCount;
}
