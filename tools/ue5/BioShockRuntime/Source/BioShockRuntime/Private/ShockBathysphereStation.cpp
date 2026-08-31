#include "ShockBathysphereStation.h"

#include "ShockGameMode.h"
#include "ShockPlayer.h"

#include "Components/BoxComponent.h"
#include "EngineUtils.h"

AShockBathysphereStation::AShockBathysphereStation()
{
	PrimaryActorTick.bCanEverTick = false;

	Trigger = CreateDefaultSubobject<UBoxComponent>(TEXT("Trigger"));
	SetRootComponent(Trigger);
	Trigger->SetBoxExtent(FVector(120.0f, 120.0f, 100.0f));
	Trigger->SetCollisionProfileName(TEXT("Trigger"));
	Trigger->OnComponentBeginOverlap.AddDynamic(this, &AShockBathysphereStation::OnTriggerBeginOverlap);
	Trigger->OnComponentEndOverlap.AddDynamic(this, &AShockBathysphereStation::OnTriggerEndOverlap);
}

void AShockBathysphereStation::OnTriggerBeginOverlap(
	UPrimitiveComponent* OverlappedComponent,
	AActor* OtherActor,
	UPrimitiveComponent* OtherComp,
	int32 OtherBodyIndex,
	bool bFromSweep,
	const FHitResult& SweepResult)
{
	(void)OverlappedComponent;
	(void)OtherComp;
	(void)OtherBodyIndex;
	(void)bFromSweep;
	(void)SweepResult;
	if (AShockPlayer* Player = Cast<AShockPlayer>(OtherActor))
	{
		OverlappingPlayer = Player;
	}
}

void AShockBathysphereStation::OnTriggerEndOverlap(
	UPrimitiveComponent* OverlappedComponent,
	AActor* OtherActor,
	UPrimitiveComponent* OtherComp,
	int32 OtherBodyIndex)
{
	(void)OverlappedComponent;
	(void)OtherComp;
	(void)OtherBodyIndex;
	if (OtherActor == OverlappingPlayer.Get())
	{
		OverlappingPlayer = nullptr;
	}
}

bool AShockBathysphereStation::TryTravelForOverlappingPlayer()
{
	if (!bUnlocked || DestinationMap.IsEmpty())
	{
		return false;
	}

	AShockPlayer* Player = OverlappingPlayer.Get();
	if (!Player)
	{
		Player = AShockPlayer::FindLocalOrFirst(GetWorld());
	}
	if (!Player)
	{
		return false;
	}

	if (AShockGameMode* GameMode = GetWorld()->GetAuthGameMode<AShockGameMode>())
	{
		GameMode->TravelToLevel(DestinationMap, DestinationStart);
		return true;
	}
	return false;
}

AShockBathysphereStation* AShockBathysphereStation::FindByMapId(UWorld* World, FName MapId)
{
	if (!World || MapId.IsNone())
	{
		return nullptr;
	}

	for (TActorIterator<AShockBathysphereStation> It(World); It; ++It)
	{
		if (*It && It->StationMapId == MapId)
		{
			return *It;
		}
	}
	return nullptr;
}
