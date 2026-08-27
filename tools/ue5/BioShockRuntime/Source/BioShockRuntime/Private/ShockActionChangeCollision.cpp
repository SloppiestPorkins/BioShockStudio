#include "ShockActionChangeCollision.h"

#include "EngineUtils.h"
#include "GameFramework/Actor.h"

UShockActionChangeCollision::UShockActionChangeCollision()
{
	ActionClassName = TEXT("ActionChangeCollision");
	CollideActors = EShockCollisionChange::DoNotChange;
	CollideWorld = EShockCollisionChange::DoNotChange;
	BlockActors = EShockCollisionChange::DoNotChange;
	BlockPlayers = EShockCollisionChange::DoNotChange;
	BlockNonZeroExtentTraces = EShockCollisionChange::DoNotChange;
	WorldGeometry = EShockCollisionChange::DoNotChange;
	BlockHavok = EShockCollisionChange::DoNotChange;
}

void UShockActionChangeCollision::Configure(FName InTargetLabel, EShockCollisionChange InCollideActors)
{
	TargetLabel = InTargetLabel;
	CollideActors = InCollideActors;
}

bool UShockActionChangeCollision::ApplyToActor(AActor* Target)
{
	bDidApplyCollideActors = false;
	if (Target == nullptr)
	{
		return false;
	}
	if (CollideActors == EShockCollisionChange::DoNotChange)
	{
		return false;
	}

	const bool bEnable = (CollideActors == EShockCollisionChange::SetToTrue);
	Target->SetActorEnableCollision(bEnable);
	bLastAppliedEnableCollision = bEnable;
	bDidApplyCollideActors = true;
	return true;
}

int32 UShockActionChangeCollision::ApplyInWorld(UWorld* World)
{
	int32 Applied = 0;
	if (!World || TargetLabel.IsNone())
	{
		return 0;
	}
	const FString Want = TargetLabel.ToString();
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
		if (ApplyToActor(Actor))
		{
			++Applied;
		}
#endif
	}
	return Applied;
}
