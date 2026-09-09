#include "ShockAirBlastPlasmid.h"

#include "Engine/World.h"
#include "EngineUtils.h"
#include "GameFramework/Character.h"
#include "ShockDamageLibrary.h"
#include "ShockPawn.h"
#include "ShockPlayer.h"

UShockAirBlastPlasmid::UShockAirBlastPlasmid()
{
	PlasmidName = TEXT("AirBlast");
	EveCost = 15.0f;
	CastCooldown = 0.5f;
	TargetingMode = EShockPlasmidTargetingMode::AoE;
	HandCastAnimation = TEXT("Generic_Fire");
	HandTint = FLinearColor(0.75f, 0.85f, 1.0f, 1.0f);
	CastFxAssetPath = TEXT("/Game/BioShockFX/Plasmids/NS_AirBlast.NS_AirBlast");
}

bool UShockAirBlastPlasmid::Cast(AShockPlayer* Caster, const FHitResult& Aim)
{
	if (!Caster)
	{
		return false;
	}
	UWorld* World = Caster->GetWorld();
	if (!World)
	{
		return false;
	}

	LastAffectedCount = 0;
	const FVector Origin = Caster->GetPlasmidMuzzleWorldLocation();
	const FVector Forward = Caster->GetControlRotation().Vector();

	for (TActorIterator<AShockPawn> It(World); It; ++It)
	{
		AShockPawn* Pawn = *It;
		if (!Pawn || Pawn == Caster || Pawn->IsDead())
		{
			continue;
		}
		const FVector Delta = Pawn->GetActorLocation() - Origin;
		const float Distance = Delta.Size();
		if (Distance > BlastRadius || Distance <= KINDA_SMALL_NUMBER)
		{
			continue;
		}
		if (FVector::DotProduct(Delta / Distance, Forward) < ConeCosine)
		{
			continue;
		}

		UShockDamageLibrary::ApplyDamage(Pawn, BlastDamage, Caster, FName(TEXT("AirBlast")));
		if (ACharacter* Character = ::Cast<ACharacter>(Pawn))
		{
			const FVector Launch = (Delta / Distance) * PawnLaunchSpeed + FVector(0.0f, 0.0f, 400.0f);
			Character->LaunchCharacter(Launch, true, true);
		}
		++LastAffectedCount;
	}

	const FVector Cone = Origin + Forward * 150.0f;
	SpawnCastBurst(Caster, Cone, Forward.Rotation(), 0.4f, 24.0f);
	UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_PLASMID cast=AirBlast affected=%d"), LastAffectedCount);
	return true;
}
