#include "ShockInsectSwarmPlasmid.h"

#include "BaseShockAI.h"
#include "DrawDebugHelpers.h"
#include "Engine/World.h"
#include "EngineUtils.h"
#include "ShockInsectSwarm.h"
#include "ShockPawn.h"
#include "ShockPlayer.h"

UShockInsectSwarmPlasmid::UShockInsectSwarmPlasmid()
{
	PlasmidName = TEXT("InsectSwarm");
	EveCost = 8.0f;
	CastCooldown = 0.5f;
	TargetingMode = EShockPlasmidTargetingMode::Trace;
}

bool UShockInsectSwarmPlasmid::Cast(AShockPlayer* Caster, const FHitResult& Aim)
{
	LastSpawnedSwarm = nullptr;

	if (!Caster)
	{
		return false;
	}

	UWorld* World = Caster->GetWorld();
	if (!World)
	{
		return false;
	}

	ABaseShockAI* Victim = ::Cast<ABaseShockAI>(Aim.GetActor());
	if (!Victim || Victim->IsDead())
	{
		const FVector Origin = Aim.bBlockingHit ? Aim.ImpactPoint : Aim.TraceEnd;
		float BestDistSq = TNumericLimits<float>::Max();
		for (TActorIterator<ABaseShockAI> It(World); It; ++It)
		{
			ABaseShockAI* AI = *It;
			if (!AI || AI->IsDead())
			{
				continue;
			}
			const float DistSq = FVector::DistSquared(Origin, AI->GetActorLocation());
			if (DistSq < BestDistSq)
			{
				BestDistSq = DistSq;
				Victim = AI;
			}
		}
	}

	if (!Victim)
	{
		return false;
	}

	const FVector SpawnLoc = Victim->GetActorLocation() + FVector(0.0f, 0.0f, 80.0f);
	FActorSpawnParameters Params;
	Params.Owner = Caster;
	Params.Instigator = Caster;
	AShockInsectSwarm* Swarm = World->SpawnActor<AShockInsectSwarm>(SpawnLoc, FRotator::ZeroRotator, Params);
	if (!Swarm)
	{
		return false;
	}

	Swarm->Configure(Caster, Victim);
	LastSpawnedSwarm = Swarm;

	DrawDebugSphere(World, SpawnLoc, 10.0f, 8, FColor(180, 255, 120), false, 0.2f);

	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_PLASMID name=InsectSwarm eve=%.0f victim=%s"),
		EveCost,
		*(Victim->GetScriptLabel().IsNone() ? Victim->GetName() : Victim->GetScriptLabel().ToString()));

	return true;
}
