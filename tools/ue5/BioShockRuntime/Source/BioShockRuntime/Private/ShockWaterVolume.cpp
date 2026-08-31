#include "ShockWaterVolume.h"

#include "Components/BoxComponent.h"
#include "Engine/OverlapResult.h"
#include "Engine/World.h"
#include "EngineUtils.h"

AShockWaterVolume::AShockWaterVolume()
{
	PrimaryActorTick.bCanEverTick = false;

	Volume = CreateDefaultSubobject<UBoxComponent>(TEXT("Volume"));
	SetRootComponent(Volume);
	Volume->SetBoxExtent(FVector(200.0f, 200.0f, 100.0f));
	Volume->SetCollisionEnabled(ECollisionEnabled::QueryOnly);
	Volume->SetCollisionResponseToAllChannels(ECR_Ignore);
	Volume->SetCollisionResponseToChannel(ECC_Pawn, ECR_Overlap);
	Volume->SetGenerateOverlapEvents(true);
}

bool AShockWaterVolume::IsActorInWater(const AActor* Actor)
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

	for (TActorIterator<AShockWaterVolume> It(World); It; ++It)
	{
		const AShockWaterVolume* Water = *It;
		if (!Water || !Water->bIsWater || !Water->Volume)
		{
			continue;
		}
		if (Water->Volume->IsOverlappingActor(Actor))
		{
			return true;
		}
		// Headless editor spawn may not fire overlap events; fall back to bounds test.
		const FBox Box = Water->Volume->Bounds.GetBox();
		if (Box.IsInside(Actor->GetActorLocation()))
		{
			return true;
		}
	}
	return false;
}

void AShockWaterVolume::RefreshOverlapsForVerify()
{
	if (Volume)
	{
		Volume->UpdateOverlaps();
	}
}
