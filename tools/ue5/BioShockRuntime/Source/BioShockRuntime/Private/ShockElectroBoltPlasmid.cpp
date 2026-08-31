#include "ShockElectroBoltPlasmid.h"

#include "BaseShockAI.h"
#include "DrawDebugHelpers.h"
#include "Engine/World.h"
#include "EngineUtils.h"
#include "ShockDamageLibrary.h"
#include "ShockPawn.h"
#include "ShockPlayer.h"
#include "ShockWaterVolume.h"

UShockElectroBoltPlasmid::UShockElectroBoltPlasmid()
{
	PlasmidName = TEXT("ElectroBolt");
	EveCost = 15.0f;
	CastCooldown = 0.5f;
	TargetingMode = EShockPlasmidTargetingMode::Trace;
}

void UShockElectroBoltPlasmid::ApplyBoltToPawn(
	AShockPlayer* Caster,
	AShockPawn* Target,
	float Damage,
	bool bFromWaterChain)
{
	if (!Caster || !Target || Target->IsDead())
	{
		return;
	}

	UShockDamageLibrary::ApplyDamage(Target, Damage, Caster, FName(TEXT("ElectroBolt")));
	if (ABaseShockAI* AI = ::Cast<ABaseShockAI>(Target))
	{
		AI->ReactToPlasmidStun(StunSeconds, Caster);
	}

	UWorld* World = Caster->GetWorld();
	if (World)
	{
		const FColor SparkColor = bFromWaterChain ? FColor(120, 200, 255) : FColor(100, 180, 255);
		DrawDebugSphere(
			World,
			Target->GetActorLocation() + FVector(0.0f, 0.0f, 50.0f),
			12.0f,
			10,
			SparkColor,
			false,
			0.25f);
	}
	++LastHitCount;
}

void UShockElectroBoltPlasmid::ChainInWater(AShockPlayer* Caster, AShockPawn* Primary, float Damage)
{
	UWorld* World = Caster ? Caster->GetWorld() : nullptr;
	if (!World || !Primary)
	{
		return;
	}

	const FVector Origin = Primary->GetActorLocation();
	for (TActorIterator<AShockPawn> It(World); It; ++It)
	{
		AShockPawn* Other = *It;
		if (!Other || Other == Primary || Other == Caster || Other->IsDead())
		{
			continue;
		}
		if (FVector::Dist(Origin, Other->GetActorLocation()) > WaterChainRadius)
		{
			continue;
		}
		if (!AShockWaterVolume::IsActorInWater(Other))
		{
			continue;
		}
		ApplyBoltToPawn(Caster, Other, Damage, true);
	}
}

bool UShockElectroBoltPlasmid::Cast(AShockPlayer* Caster, const FHitResult& Aim)
{
	LastHitCount = 0;
	bLastCastInWater = false;

	if (!Caster)
	{
		return false;
	}

	UWorld* World = Caster->GetWorld();
	AShockPawn* TargetPawn = ::Cast<AShockPawn>(Aim.GetActor());
	const bool bHitActorInWater = Aim.GetActor() && AShockWaterVolume::IsActorInWater(Aim.GetActor());
	const bool bTargetInWater = TargetPawn && AShockWaterVolume::IsActorInWater(TargetPawn);
	bLastCastInWater = bHitActorInWater || bTargetInWater;

	float Damage = BoltDamage;
	if (bLastCastInWater)
	{
		Damage *= 2.0f;
	}

	if (TargetPawn && !TargetPawn->IsDead())
	{
		ApplyBoltToPawn(Caster, TargetPawn, Damage, false);
		if (bLastCastInWater)
		{
			ChainInWater(Caster, TargetPawn, Damage);
		}
	}

	if (World && Aim.bBlockingHit)
	{
		DrawDebugSphere(World, Aim.ImpactPoint, 8.0f, 8, FColor(180, 220, 255), false, 0.15f);
	}

	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_PLASMID name=ElectroBolt eve=%.0f hit=%d water=%d"),
		EveCost,
		LastHitCount,
		bLastCastInWater ? 1 : 0);

	return true;
}
