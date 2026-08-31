#include "ShockActionSpawnPickup.h"

#include "EngineUtils.h"
#include "Engine/Engine.h"
#include "Engine/TargetPoint.h"
#include "Engine/World.h"
#include "GameFramework/Actor.h"

UShockActionSpawnPickup::UShockActionSpawnPickup()
{
	ActionClassName = TEXT("ActionSpawnPickup");
}

void UShockActionSpawnPickup::Configure(
	FName InActorLabel,
	FName InTarget,
	FName InPickupClass,
	FName InItemClass,
	int32 InStack,
	bool bInStartsPhysical)
{
	ActorLabel = InActorLabel;
	TargetActorLabel = InTarget;
	PickupClassName = InPickupClass;
	ItemClassName = InItemClass;
	StackSize = InStack;
	bStartsPhysical = bInStartsPhysical;
}

bool UShockActionSpawnPickup::RequestSpawn()
{
	if (TargetActorLabel.IsNone() || PickupClassName.IsNone())
	{
		return false;
	}
	LastTargetActorLabel = TargetActorLabel;
	return true;
}

AActor* UShockActionSpawnPickup::SpawnAtLocation(UObject* WorldContextObject, FVector Location)
{
	LastSpawnedActor = nullptr;
	if (!RequestSpawn() || !WorldContextObject)
	{
		return nullptr;
	}

	UWorld* World = GEngine ? GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::ReturnNull) : nullptr;
	if (!World)
	{
		return nullptr;
	}

	FActorSpawnParameters Params;
	Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
	ATargetPoint* Spawned = World->SpawnActor<ATargetPoint>(ATargetPoint::StaticClass(), Location, FRotator::ZeroRotator, Params);
	if (!Spawned)
	{
		return nullptr;
	}

#if WITH_EDITOR
	if (!ActorLabel.IsNone())
	{
		Spawned->SetActorLabel(ActorLabel.ToString());
	}
#endif
	LastSpawnedActor = Spawned;
	return Spawned;
}

AActor* UShockActionSpawnPickup::SpawnInWorld(UWorld* World)
{
	if (!World || TargetActorLabel.IsNone())
	{
		return nullptr;
	}
	const FString Want = TargetActorLabel.ToString();
	for (TActorIterator<AActor> It(World); It; ++It)
	{
		AActor* Actor = *It;
		if (!Actor)
		{
			continue;
		}
#if WITH_EDITOR
		if (!Actor->GetActorLabel().Equals(Want, ESearchCase::CaseSensitive))
		{
			continue;
		}
		return SpawnAtLocation(World, Actor->GetActorLocation());
#else
		(void)Actor;
#endif
	}
	return nullptr;
}

bool UShockActionSpawnPickup::ApplyInWorld(const FShockActionContext& Ctx)
{
	return SpawnInWorld(Ctx.World) != nullptr;
}
