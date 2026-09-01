#include "ShockWinterBlastPlasmid.h"

#include "BaseShockAI.h"
#include "DrawDebugHelpers.h"
#include "Engine/World.h"
#include "EngineUtils.h"
#include "ShockDamageLibrary.h"
#include "ShockPawn.h"
#include "ShockPlayer.h"

UShockWinterBlastPlasmid::UShockWinterBlastPlasmid()
{
	PlasmidName = TEXT("WinterBlast");
	EveCost = 13.0f;
	CastCooldown = 0.5f;
	TargetingMode = EShockPlasmidTargetingMode::Trace;
}

bool UShockWinterBlastPlasmid::Cast(AShockPlayer* Caster, const FHitResult& Aim)
{
	LastFrozenCount = 0;

	if (!Caster)
	{
		return false;
	}

	UWorld* World = Caster->GetWorld();
	if (!World)
	{
		return false;
	}

	const FVector Origin = Caster->GetActorLocation();
	const FVector Forward = Caster->GetActorForwardVector().GetSafeNormal2D();
	const float CosHalf = FMath::Cos(FMath::DegreesToRadians(ConeHalfAngleDegrees));
	const float RadiusSq = ConeRadius * ConeRadius;

	for (TActorIterator<ABaseShockAI> It(World); It; ++It)
	{
		ABaseShockAI* AI = *It;
		if (!AI || AI->IsDead())
		{
			continue;
		}

		const FVector ToTarget = AI->GetActorLocation() - Origin;
		if (ToTarget.SizeSquared2D() > RadiusSq)
		{
			continue;
		}

		const FVector Dir = ToTarget.GetSafeNormal2D();
		if (FVector::DotProduct(Forward, Dir) < CosHalf)
		{
			continue;
		}

		UShockDamageLibrary::ApplyDamage(AI, BurstDamage, Caster, FName(TEXT("WinterBlast")));
		AI->FreezeSolid(FreezeSeconds, Caster);
		++LastFrozenCount;

		DrawDebugSphere(
			World,
			AI->GetActorLocation() + FVector(0.0f, 0.0f, 50.0f),
			12.0f,
			10,
			FColor(140, 200, 255),
			false,
			0.25f);
	}

	if (Aim.bBlockingHit)
	{
		DrawDebugSphere(World, Aim.ImpactPoint, 8.0f, 8, FColor(160, 220, 255), false, 0.15f);
	}

	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_PLASMID name=WinterBlast eve=%.0f frozen=%d"),
		EveCost,
		LastFrozenCount);

	return true;
}
