#include "ShockActionSpawnAI.h"

#include "BaseShockAI.h"
#include "Engine/Engine.h"
#include "Engine/World.h"

UShockActionSpawnAI::UShockActionSpawnAI()
{
	ActionClassName = TEXT("ActionSpawnAI");
	bCorpseCanBeRemoved = true;
}

void UShockActionSpawnAI::Configure(
	FName InAIType,
	FName InSpawnLocationLabel,
	FName InSpawnedAILabel,
	float InMinRadius,
	float InMaxRadius,
	bool bInForceSpawn)
{
	AITypeToSpawn = InAIType;
	SpawnLocationLabel = InSpawnLocationLabel;
	SpawnedAILabel = InSpawnedAILabel;
	MinRadiusToSpawnAroundSpawnLoc = InMinRadius;
	MaxRadiusToSpawnAroundSpawnLoc = InMaxRadius;
	bForceSpawn = bInForceSpawn;
}

bool UShockActionSpawnAI::RequestSpawn()
{
	if (AITypeToSpawn.IsNone())
	{
		return false;
	}
	LastRequestedAIType = AITypeToSpawn;
	LastRequestedLocationLabel = SpawnLocationLabel;
	return true;
}

AActor* UShockActionSpawnAI::SpawnAtLocation(UObject* WorldContextObject, FVector Location)
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
	ABaseShockAI* AI = World->SpawnActor<ABaseShockAI>(ABaseShockAI::StaticClass(), Location, FRotator::ZeroRotator, Params);
	if (!AI)
	{
		return nullptr;
	}

	AI->ConfigureIdentity(AITypeToSpawn, SpawnedAILabel.IsNone() ? AITypeToSpawn : SpawnedAILabel);
	AI->EnsureHealthInitialized();
	LastSpawnedActor = AI;
	return AI;
}
