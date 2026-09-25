#include "ShockOilSlickVolume.h"

#include "BaseShockAI.h"
#include "Components/BoxComponent.h"
#include "Engine/World.h"
#include "EngineUtils.h"
#include "ShockDamageLibrary.h"
#include "ShockPawn.h"
#include "ShockPlayer.h"
#include "ShockScriptSubsystem.h"

AShockOilSlickVolume::AShockOilSlickVolume()
{
	PrimaryActorTick.bCanEverTick = false;

	Volume = CreateDefaultSubobject<UBoxComponent>(TEXT("Volume"));
	SetRootComponent(Volume);
	Volume->SetBoxExtent(FVector(200.0f, 200.0f, 50.0f));
	Volume->SetCollisionEnabled(ECollisionEnabled::QueryOnly);
	Volume->SetCollisionResponseToAllChannels(ECR_Ignore);
	Volume->SetCollisionResponseToChannel(ECC_Pawn, ECR_Overlap);
	Volume->SetGenerateOverlapEvents(true);
}

bool AShockOilSlickVolume::IsActorOverlapping(const AActor* Actor) const
{
	if (!Actor || !bIsOil || !Volume)
	{
		return false;
	}
	if (Volume->IsOverlappingActor(Actor))
	{
		return true;
	}
	const FBox Box = Volume->Bounds.GetBox();
	return Box.IsInside(Actor->GetActorLocation());
}

bool AShockOilSlickVolume::IsActorInOil(const AActor* Actor)
{
	if (!Actor)
	{
		return false;
	}

	UWorld* World = Actor->GetWorld();
	if (!World)
	{
		return false;
	}

	for (TActorIterator<AShockOilSlickVolume> It(World); It; ++It)
	{
		const AShockOilSlickVolume* Oil = *It;
		if (!Oil || !Oil->bIsOil || Oil->bIgnited)
		{
			continue;
		}
		if (Oil->IsActorOverlapping(Actor))
		{
			return true;
		}
	}
	return false;
}

AShockOilSlickVolume* AShockOilSlickVolume::FindSlickForActorOrPoint(
	UWorld* World,
	const AActor* Actor,
	FVector Point)
{
	if (!World)
	{
		return nullptr;
	}

	for (TActorIterator<AShockOilSlickVolume> It(World); It; ++It)
	{
		AShockOilSlickVolume* Oil = *It;
		if (!Oil || !Oil->bIsOil || Oil->bIgnited)
		{
			continue;
		}
		if (Actor && Oil->IsActorOverlapping(Actor))
		{
			return Oil;
		}
		if (Oil->Volume)
		{
			const FBox Box = Oil->Volume->Bounds.GetBox();
			if (Box.IsInside(Point))
			{
				return Oil;
			}
		}
	}
	return nullptr;
}

void AShockOilSlickVolume::IgniteSlick(
	AShockPlayer* Caster,
	float BurstDamage,
	float BurnSeconds,
	float BurnDps)
{
	if (bIgnited || !bIsOil)
	{
		return;
	}
	bIgnited = true;

	// PLAUSIBLE — oil pool burns longer than a direct Incinerate tick.
	const float OilBurnSeconds = BurnSeconds * 2.5f;

	UWorld* World = GetWorld();
	if (!World)
	{
		return;
	}

	// Medical scripts listen for MessageRAReacted from ScriptedOilSlick* labels when oil ignites.
	if (Caster)
	{
		Caster->NotifyReactedWithActor(this);
	}
	else if (UShockScriptSubsystem* Sub = UShockScriptSubsystem::Get(World))
	{
		const FString Src = UShockScriptSubsystem::ResolveMessageSourceLabel(this);
		if (!Src.IsEmpty())
		{
			{
		TMap<FString, FString> Fields;
		Fields.Add(TEXT("RA"), Src);
		Sub->DispatchMessageLoggedWithFields(FName(TEXT("MessageRAReacted")), Src, Fields);
	}
		}
	}

	for (TActorIterator<AShockPawn> It(World); It; ++It)
	{
		AShockPawn* Pawn = *It;
		if (!Pawn || Pawn == Caster || Pawn->IsDead() || !IsActorOverlapping(Pawn))
		{
			continue;
		}

		UShockDamageLibrary::ApplyDamage(Pawn, BurstDamage, Caster, FName(TEXT("Incinerate")));
		if (ABaseShockAI* AI = ::Cast<ABaseShockAI>(Pawn))
		{
			AI->Ignite(OilBurnSeconds, BurnDps, Caster);
		}
	}
}

void AShockOilSlickVolume::RefreshOverlapsForVerify()
{
	if (Volume)
	{
		Volume->UpdateOverlaps();
	}
}
