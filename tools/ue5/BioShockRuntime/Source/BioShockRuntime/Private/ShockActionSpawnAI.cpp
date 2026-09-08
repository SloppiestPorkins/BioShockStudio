#include "ShockActionSpawnAI.h"

#include "BaseShockAI.h"
#include "ShockEnemySpawner.h"
#include "ShockPlayer.h"
#include "Components/CapsuleComponent.h"
#include "EngineUtils.h"
#include "Engine/Engine.h"
#include "Engine/World.h"
#include "GameFramework/Actor.h"

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

	const float HalfHeight =
		GetDefault<ABaseShockAI>()->GetCapsuleComponent()->GetUnscaledCapsuleHalfHeight() + 2.0f;
	FVector GroundedLocation;
	if (!AShockAggressorSpawner::FindGroundedSpawnLocation(
			World, Location, HalfHeight, nullptr, GroundedLocation))
	{
		return nullptr;
	}

	FActorSpawnParameters Params;
	Params.SpawnCollisionHandlingOverride =
		ESpawnActorCollisionHandlingMethod::AdjustIfPossibleButDontSpawnIfColliding;
	ABaseShockAI* AI = World->SpawnActor<ABaseShockAI>(
		ABaseShockAI::StaticClass(), GroundedLocation, FRotator::ZeroRotator, Params);
	if (!AI)
	{
		return nullptr;
	}

	AI->ConfigureIdentity(AITypeToSpawn, SpawnedAILabel.IsNone() ? AITypeToSpawn : SpawnedAILabel);
	AI->ApplyArchetypeLookup(AITypeToSpawn);
	AI->EnsureHealthInitialized();
	if (AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World))
	{
#if WITH_EDITOR
		Player->SetActorLabel(TEXT("SlicePlayer"));
#endif
		AI->AddTargetToAttackOnSight(FName(TEXT("SlicePlayer")));
		AI->ScriptedAttackTarget(Player);
	}
#if WITH_EDITOR
	if (!SpawnedAILabel.IsNone())
	{
		AI->SetActorLabel(SpawnedAILabel.ToString());
	}
#endif
	LastSpawnedActor = AI;
	return AI;
}

AActor* UShockActionSpawnAI::SpawnInWorld(UWorld* World)
{
	if (!World || SpawnLocationLabel.IsNone())
	{
		return nullptr;
	}
	for (TActorIterator<AShockAggressorSpawner> It(World); It; ++It)
	{
		if (*It && (*It)->MatchesLabel(SpawnLocationLabel))
		{
			if (AActor* Spawned = (*It)->SpawnForScript(AITypeToSpawn, SpawnedAILabel))
			{
				LastSpawnedActor = Spawned;
				return Spawned;
			}
		}
	}
	const FString Want = SpawnLocationLabel.ToString();
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

bool UShockActionSpawnAI::ApplyInWorld(const FShockActionContext& Ctx)
{
	return SpawnInWorld(Ctx.World) != nullptr;
}
