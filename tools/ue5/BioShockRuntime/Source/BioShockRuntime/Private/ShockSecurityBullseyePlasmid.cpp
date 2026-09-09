#include "ShockSecurityBullseyePlasmid.h"

#include "BaseShockAI.h"
#include "Engine/World.h"
#include "EngineUtils.h"
#include "ShockPlayer.h"
#include "ShockSecurityBot.h"

UShockSecurityBullseyePlasmid::UShockSecurityBullseyePlasmid()
{
	PlasmidName = TEXT("SecurityBullseye");
	EveCost = 5.0f;
	CastCooldown = 0.5f;
	TargetingMode = EShockPlasmidTargetingMode::Trace;
	HandCastAnimation = TEXT("Generic_Fire");
	HandTint = FLinearColor(1.0f, 0.55f, 0.1f, 1.0f);
	CastFxAssetPath = TEXT("/Game/BioShockFX/Plasmids/NS_SecurityBullseye.NS_SecurityBullseye");
}

bool UShockSecurityBullseyePlasmid::Cast(AShockPlayer* Caster, const FHitResult& Aim)
{
	ABaseShockAI* Target = ::Cast<ABaseShockAI>(Aim.GetActor());
	if (!Caster || !Target || Target->IsDead())
	{
		return false;
	}
	UWorld* World = Caster->GetWorld();
	if (!World)
	{
		return false;
	}

	LastMarkedActor = Target;
	LastCommandedBotCount = 0;

	// Give every splicer a reason to fear the bots: the marked AI keeps its label, and the bots
	// are told to hunt it.
	const FName TargetLabel = Target->GetFName();
	for (TActorIterator<AShockSecurityBot> It(World); It; ++It)
	{
		if (AShockSecurityBot* Bot = *It)
		{
			Bot->CommandAttackLabel(TargetLabel);
			++LastCommandedBotCount;
		}
	}
	// Nearby splicers see the marked one as a threat magnet — they scatter from it.
	Target->NotifyAggroFromPlayer(Caster);

	SpawnCastBeam(Caster, Caster->GetPlasmidMuzzleWorldLocation(), Target->GetActorLocation(), 0.4f, 3.0f);
	SpawnCastBurst(Caster, Target->GetActorLocation() + FVector(0, 0, 60), FRotator::ZeroRotator, 1.2f, 14.0f);
	UE_LOG(
		LogTemp, Display, TEXT("BIOSHOCK_PLASMID cast=SecurityBullseye target=%s bots=%d"),
		*TargetLabel.ToString(), LastCommandedBotCount);
	return true;
}
