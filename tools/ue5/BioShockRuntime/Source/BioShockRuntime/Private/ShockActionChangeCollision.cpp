#include "ShockActionChangeCollision.h"

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
