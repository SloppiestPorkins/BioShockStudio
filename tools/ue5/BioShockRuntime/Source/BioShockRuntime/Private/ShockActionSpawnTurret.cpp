#include "ShockActionSpawnTurret.h"

#include "EngineUtils.h"
#include "Engine/Engine.h"
#include "Engine/World.h"
#include "GameFramework/Actor.h"
#include "ShockSecurityDevice.h"
#include "ShockTurret.h"

UShockActionSpawnTurret::UShockActionSpawnTurret()
{
	ActionClassName = TEXT("ActionSpawnTurret");
}

void UShockActionSpawnTurret::Configure(FName InSpawner)
{
	SpawnerLabel = InSpawner;
}

bool UShockActionSpawnTurret::RequestSpawn()
{
	if (SpawnerLabel.IsNone())
	{
		return false;
	}
	LastSpawnerLabel = SpawnerLabel;
	return true;
}

AActor* UShockActionSpawnTurret::SpawnAtLocation(UObject* WorldContextObject, FVector Location)
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
	AShockTurret* Spawned = World->SpawnActor<AShockTurret>(
		AShockTurret::StaticClass(),
		Location,
		FRotator::ZeroRotator,
		Params);
	if (!Spawned)
	{
		return nullptr;
	}

	Spawned->SetDeviceLabel(SpawnerLabel);
	Spawned->SetAllegiance(EShockDeviceAllegiance::Hostile);
#if WITH_EDITOR
	Spawned->SetActorLabel(SpawnerLabel.ToString());
#endif

	LastSpawnedActor = Spawned;
	return Spawned;
}

AActor* UShockActionSpawnTurret::SpawnInWorld(UWorld* World)
{
	if (!World || SpawnerLabel.IsNone())
	{
		return nullptr;
	}
	const FString Want = SpawnerLabel.ToString();
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

bool UShockActionSpawnTurret::ApplyInWorld(const FShockActionContext& Ctx)
{
	return SpawnInWorld(Ctx.World) != nullptr;
}
