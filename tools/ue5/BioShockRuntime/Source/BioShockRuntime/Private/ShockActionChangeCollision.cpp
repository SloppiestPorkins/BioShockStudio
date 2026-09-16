#include "ShockActionChangeCollision.h"

#include "Components/PrimitiveComponent.h"
#include "EngineUtils.h"
#include "GameFramework/Actor.h"

namespace
{
	bool ApplyResponse(
		const TArray<UPrimitiveComponent*>& Components,
		EShockCollisionChange Change,
		ECollisionChannel Channel)
	{
		if (Change == EShockCollisionChange::DoNotChange || Components.IsEmpty())
		{
			return false;
		}
		const ECollisionResponse Response = Change == EShockCollisionChange::SetToTrue
			? ECR_Block
			: ECR_Ignore;
		for (UPrimitiveComponent* Component : Components)
		{
			if (Component)
			{
				Component->SetCollisionResponseToChannel(Channel, Response);
			}
		}
		return true;
	}
}

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

void UShockActionChangeCollision::ConfigureAll(
	FName InTargetLabel,
	EShockCollisionChange InCollideActors,
	EShockCollisionChange InCollideWorld,
	EShockCollisionChange InBlockActors,
	EShockCollisionChange InBlockPlayers,
	EShockCollisionChange InBlockNonZeroExtentTraces,
	EShockCollisionChange InWorldGeometry,
	EShockCollisionChange InBlockHavok)
{
	TargetLabel = InTargetLabel;
	CollideActors = InCollideActors;
	CollideWorld = InCollideWorld;
	BlockActors = InBlockActors;
	BlockPlayers = InBlockPlayers;
	BlockNonZeroExtentTraces = InBlockNonZeroExtentTraces;
	WorldGeometry = InWorldGeometry;
	BlockHavok = InBlockHavok;
}

bool UShockActionChangeCollision::ApplyToActor(AActor* Target)
{
	bDidApplyCollideActors = false;
	if (Target == nullptr)
	{
		return false;
	}

	bool bApplied = false;
	if (CollideActors != EShockCollisionChange::DoNotChange)
	{
		const bool bEnable = CollideActors == EShockCollisionChange::SetToTrue;
		Target->SetActorEnableCollision(bEnable);
		bLastAppliedEnableCollision = bEnable;
		bDidApplyCollideActors = true;
		bApplied = true;
	}

	TInlineComponentArray<UPrimitiveComponent*> InlineComponents(Target);
	const TArray<UPrimitiveComponent*> Components(InlineComponents);
	// UE2 Actor flags have no 1:1 UE5 equivalent. These channel mappings preserve which class of
	// collision each authored flag gated; WorldGeometry follows CollideWorld on WorldStatic, and
	// therefore deliberately wins when malformed data authors contradictory values for both.
	bApplied |= ApplyResponse(Components, CollideWorld, ECC_WorldStatic);
	bApplied |= ApplyResponse(Components, BlockActors, ECC_WorldDynamic);
	bApplied |= ApplyResponse(Components, BlockPlayers, ECC_Pawn);
	bApplied |= ApplyResponse(Components, BlockNonZeroExtentTraces, ECC_Visibility);
	bApplied |= ApplyResponse(Components, WorldGeometry, ECC_WorldStatic);
	bApplied |= ApplyResponse(Components, BlockHavok, ECC_PhysicsBody);
	return bApplied;
}

int32 UShockActionChangeCollision::GetResponseToChannelForVerify(AActor* Target, int32 Channel) const
{
	if (!Target || Channel < 0 || Channel >= ECollisionChannel::ECC_MAX)
	{
		return INDEX_NONE;
	}
	if (UPrimitiveComponent* Component = Target->FindComponentByClass<UPrimitiveComponent>())
	{
		return static_cast<int32>(
			Component->GetCollisionResponseToChannel(static_cast<ECollisionChannel>(Channel)));
	}
	return INDEX_NONE;
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

bool UShockActionChangeCollision::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World) > 0;
}
