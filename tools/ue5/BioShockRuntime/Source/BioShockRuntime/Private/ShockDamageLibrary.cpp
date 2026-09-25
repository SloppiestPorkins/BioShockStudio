#include "ShockDamageLibrary.h"

#include "BaseShockAI.h"
#include "EngineUtils.h"
#include "GameFramework/Actor.h"
#include "ShockPawn.h"
#include "ShockPhysicsLibrary.h"
#include "ShockPlayer.h"
#include "ShockScriptSubsystem.h"

namespace
{
void DispatchPawnMessageSources(
	UWorld* World, FName MessageClass, AShockPawn* Pawn, AActor* Damager = nullptr)
{
	if (!World || !Pawn)
	{
		return;
	}
	UShockScriptSubsystem* Sub = UShockScriptSubsystem::Get(World);
	if (!Sub)
	{
		return;
	}
	const FString Label = UShockScriptSubsystem::ResolveMessageSourceLabel(Pawn);

	// The message's own fields, for a script's messageFilter (PawnLabel=..., PawnClass=...).
	// PawnClass is only supplied when the AI carries a UE2-style class name (SpawnedBouncer,
	// SpawnedMeleeThug ...): our older hand-configured types ("ThuggishSplicer") are a different
	// naming scheme, and offering them would wrongly rule scripts out instead of letting the
	// field pass as "unknown".
	TMap<FString, FString> Fields;
	if (!Label.IsEmpty())
	{
		Fields.Add(TEXT("PawnLabel"), Label);
	}
	if (Damager)
	{
		const FString DamagerLabel = UShockScriptSubsystem::ResolveMessageSourceLabel(Damager);
		if (!DamagerLabel.IsEmpty())
		{
			Fields.Add(TEXT("DamagerLabel"), DamagerLabel);
		}
	}
	if (const ABaseShockAI* AI = Cast<ABaseShockAI>(Pawn))
	{
		const FString ClassName = AI->AITypeName.ToString();
		if (ClassName.StartsWith(TEXT("Spawned")))
		{
			Fields.Add(TEXT("PawnClass"), ClassName);
		}
	}

	if (!Label.IsEmpty())
	{
		Sub->DispatchMessageLoggedWithFields(MessageClass, Label, Fields);
	}
	// TriggeredBy="all" / "All" means any pawn (DispatchLevelEntryMessages uses both casings).
	Sub->DispatchMessageLoggedWithFields(MessageClass, TEXT("All"), Fields);
	Sub->DispatchMessageLoggedWithFields(MessageClass, TEXT("all"), Fields);
}
} // namespace

AActor* UShockDamageLibrary::FindActorByLabel(UWorld* World, FName Label)
{
	return UShockPhysicsLibrary::FindActorByLabel(World, Label);
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

float UShockDamageLibrary::ApplyDamage(
	AActor* Target,
	float Amount,
	AActor* Instigator,
	FName DamageType,
	FVector HitImpulseDirection,
	FVector HitLocation,
	FName HitBone)
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
		FVector ImpulseDirection = HitImpulseDirection.GetSafeNormal();
		if (ImpulseDirection.IsNearlyZero() && Instigator)
		{
			ImpulseDirection =
				(AI->GetActorLocation() - Instigator->GetActorLocation()).GetSafeNormal();
		}
		const FVector ResolvedLocation = HitLocation.IsNearlyZero()
			? AI->GetActorLocation() + FVector(0.0f, 0.0f, 60.0f)
			: HitLocation;
		AI->RecordRagdollHit(
			ImpulseDirection * FMath::Clamp(Amount * 20.0f, 250.0f, 1400.0f),
			ResolvedLocation,
			HitBone);
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
				DispatchPawnMessageSources(Pawn->GetWorld(), FName(TEXT("MessagePawnTookDamage")), Pawn, Instigator);
			}
			return Applied;
		}
	}

	// Guard re-entry: only the first transition into dead fires death messages / OnDeathFromDamage.
	const bool bWasDead = Pawn->bIsDead;
	Pawn->CurrentHealth = FMath::Max(0.0f, Before - Applied);
	if (Pawn->CurrentHealth <= 0.0f)
	{
		Pawn->bIsDead = true;
	}
	// TookDamage before Died on the killing blow (scripts listening for either must see a stable order).
	if (Applied > 0.0f && !bWasDead)
	{
		DispatchPawnMessageSources(Pawn->GetWorld(), FName(TEXT("MessagePawnTookDamage")), Pawn, Instigator);
	}
	if (!bWasDead && Pawn->bIsDead)
	{
		DispatchPawnMessageSources(Pawn->GetWorld(), FName(TEXT("MessagePawnDied")), Pawn);
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
		if (Applied > 0.0f)
		{
			Player->NoteDamageHit(Instigator);
		}
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
