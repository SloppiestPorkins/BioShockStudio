#include "ShockIncineratePlasmid.h"

#include "BaseShockAI.h"
#include "DrawDebugHelpers.h"
#include "Engine/World.h"
#include "ShockDamageLibrary.h"
#include "ShockOilSlickVolume.h"
#include "ShockPawn.h"
#include "ShockPlayer.h"

UShockIncineratePlasmid::UShockIncineratePlasmid()
{
	PlasmidName = TEXT("Incinerate");
	EveCost = 8.0f;
	CastCooldown = 0.5f;
	TargetingMode = EShockPlasmidTargetingMode::Trace;
}

void UShockIncineratePlasmid::ApplyIncinerateToPawn(AShockPlayer* Caster, AShockPawn* Target)
{
	if (!Caster || !Target || Target->IsDead())
	{
		return;
	}

	UShockDamageLibrary::ApplyDamage(Target, BurstDamage, Caster, FName(TEXT("Incinerate")));
	if (ABaseShockAI* AI = ::Cast<ABaseShockAI>(Target))
	{
		AI->Ignite(BurnSeconds, BurnDps, Caster);
	}

	if (UWorld* World = Caster->GetWorld())
	{
		DrawDebugSphere(
			World,
			Target->GetActorLocation() + FVector(0.0f, 0.0f, 50.0f),
			12.0f,
			10,
			FColor(255, 120, 40),
			false,
			0.25f);
	}
	++LastHitCount;
}

bool UShockIncineratePlasmid::Cast(AShockPlayer* Caster, const FHitResult& Aim)
{
	LastHitCount = 0;
	bLastCastOnOil = false;

	if (!Caster)
	{
		return false;
	}

	UWorld* World = Caster->GetWorld();
	AShockPawn* TargetPawn = ::Cast<AShockPawn>(Aim.GetActor());
	const FVector ImpactPoint = Aim.bBlockingHit ? Aim.ImpactPoint : Aim.TraceEnd;

	if (AShockOilSlickVolume* Oil = AShockOilSlickVolume::FindSlickForActorOrPoint(
			World,
			Aim.GetActor(),
			ImpactPoint))
	{
		bLastCastOnOil = true;
		Oil->IgniteSlick(Caster, BurstDamage, BurnSeconds, BurnDps);
		LastHitCount = 1;
	}
	else if (TargetPawn && !TargetPawn->IsDead())
	{
		ApplyIncinerateToPawn(Caster, TargetPawn);
	}

	if (World && Aim.bBlockingHit)
	{
		DrawDebugSphere(World, Aim.ImpactPoint, 8.0f, 8, FColor(255, 140, 50), false, 0.15f);
	}

	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_PLASMID name=Incinerate eve=%.0f hit=%d oil=%d"),
		EveCost,
		LastHitCount,
		bLastCastOnOil ? 1 : 0);

	return true;
}
