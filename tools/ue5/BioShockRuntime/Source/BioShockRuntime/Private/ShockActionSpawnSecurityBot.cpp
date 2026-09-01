#include "ShockActionSpawnSecurityBot.h"

#include "EngineUtils.h"
#include "Engine/World.h"
#include "GameFramework/Actor.h"
#include "ShockPlayer.h"
#include "ShockSecuritySubsystem.h"

UShockActionSpawnSecurityBot::UShockActionSpawnSecurityBot()
{
	ActionClassName = TEXT("ActionSpawnSecurityBot");
}

void UShockActionSpawnSecurityBot::Configure(FName InSpawner, bool bInGive, FName InPawn)
{
	SpawnerLabel = InSpawner;
	bImmediatelyGiveBotToPawn = bInGive;
	ReceivingPawnLabel = InPawn;
}

bool UShockActionSpawnSecurityBot::RequestSpawn()
{
	if (SpawnerLabel.IsNone())
	{
		return false;
	}
	LastSpawnerLabel = SpawnerLabel;
	return true;
}

int32 UShockActionSpawnSecurityBot::ApplyInWorld(UWorld* World)
{
	if (!RequestSpawn() || !World)
	{
		return 0;
	}

	AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World);
	if (!Player)
	{
		return 0;
	}

	FVector SpawnLoc = Player->GetActorLocation();
	const FString Want = SpawnerLabel.ToString();
	for (TActorIterator<AActor> It(World); It; ++It)
	{
		AActor* Actor = *It;
		if (!Actor)
		{
			continue;
		}
#if WITH_EDITOR
		if (Actor->GetActorLabel().Equals(Want, ESearchCase::CaseSensitive))
		{
			SpawnLoc = Actor->GetActorLocation();
			break;
		}
#endif
	}

	UShockSecuritySubsystem* Security = UShockSecuritySubsystem::Get(World);
	if (!Security)
	{
		return 0;
	}

	return Security->SpawnBotsNear(SpawnLoc, 1, Player);
}

bool UShockActionSpawnSecurityBot::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World) > 0;
}
