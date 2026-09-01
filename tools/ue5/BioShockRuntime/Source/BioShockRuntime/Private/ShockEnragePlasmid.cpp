#include "ShockEnragePlasmid.h"

#include "BaseShockAI.h"
#include "DrawDebugHelpers.h"
#include "Engine/World.h"
#include "ShockPawn.h"
#include "ShockPlayer.h"

UShockEnragePlasmid::UShockEnragePlasmid()
{
	PlasmidName = TEXT("Enrage");
	EveCost = 8.0f; // PLAUSIBLE — no BioAmmoCost in surviving Enrage decomp
	CastCooldown = 0.5f;
	TargetingMode = EShockPlasmidTargetingMode::Trace;
}

bool UShockEnragePlasmid::Cast(AShockPlayer* Caster, const FHitResult& Aim)
{
	LastTargetLabel = NAME_None;

	if (!Caster)
	{
		return false;
	}

	ABaseShockAI* TargetAI = ::Cast<ABaseShockAI>(Aim.GetActor());
	if (!TargetAI || TargetAI->IsDead())
	{
		return false;
	}

	TargetAI->ApplyEnrage(EnrageDuration, Caster);
	LastTargetLabel = TargetAI->GetScriptLabel();

	if (UWorld* World = Caster->GetWorld())
	{
		DrawDebugSphere(
			World,
			TargetAI->GetActorLocation() + FVector(0.0f, 0.0f, 50.0f),
			12.0f,
			10,
			FColor(255, 80, 180),
			false,
			0.25f);
	}

	const FString TargetName = LastTargetLabel.IsNone() ? TargetAI->GetName() : LastTargetLabel.ToString();
	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_PLASMID name=Enrage eve=%.0f target=%s"),
		EveCost,
		*TargetName);

	return true;
}
