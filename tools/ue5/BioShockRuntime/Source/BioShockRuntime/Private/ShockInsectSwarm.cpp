#include "ShockInsectSwarm.h"

#include "BaseShockAI.h"
#include "Engine/World.h"
#include "EngineUtils.h"
#include "ShockDamageLibrary.h"
#include "ShockPlayer.h"

AShockInsectSwarm::AShockInsectSwarm()
{
	PrimaryActorTick.bCanEverTick = true;
}

void AShockInsectSwarm::Configure(AShockPlayer* InCaster, ABaseShockAI* InitialVictim)
{
	Caster = InCaster;
	CurrentVictim = InitialVictim;
	RemainingLife = LifeSeconds;
}

void AShockInsectSwarm::AdvanceForVerify(float DeltaSeconds)
{
	AdvanceSwarm(DeltaSeconds);
}

void AShockInsectSwarm::Tick(float DeltaSeconds)
{
	Super::Tick(DeltaSeconds);
	AdvanceSwarm(DeltaSeconds);
}

ABaseShockAI* AShockInsectSwarm::PickVictim() const
{
	UWorld* World = GetWorld();
	if (!World)
	{
		return nullptr;
	}

	ABaseShockAI* Best = nullptr;
	float BestDistSq = TNumericLimits<float>::Max();
	const FVector Origin = GetActorLocation();

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
			Best = AI;
		}
	}
	return Best;
}

void AShockInsectSwarm::AdvanceSwarm(float DeltaSeconds)
{
	if (RemainingLife <= 0.0f)
	{
		return;
	}

	RemainingLife = FMath::Max(0.0f, RemainingLife - DeltaSeconds);
	if (RemainingLife <= 0.0f)
	{
		UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_SWARM_END"));
		Destroy();
		return;
	}

	if (!CurrentVictim || CurrentVictim->IsDead())
	{
		CurrentVictim = PickVictim();
	}

	if (!CurrentVictim)
	{
		return;
	}

	SetActorLocation(CurrentVictim->GetActorLocation() + FVector(0.0f, 0.0f, 80.0f));

	const float TickDamage = SwarmDps * DeltaSeconds;
	if (TickDamage > 0.0f)
	{
		UShockDamageLibrary::ApplyDamage(
			CurrentVictim,
			TickDamage,
			Caster,
			FName(TEXT("InsectSwarm")));
	}
	CurrentVictim->ReactToPlasmidStun(DistractSeconds, Caster);
}
