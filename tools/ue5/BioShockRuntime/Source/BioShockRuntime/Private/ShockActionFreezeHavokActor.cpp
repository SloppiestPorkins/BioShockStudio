#include "ShockActionFreezeHavokActor.h"

#include "EngineUtils.h"
#include "GameFramework/Actor.h"
#include "Components/PrimitiveComponent.h"

UShockActionFreezeHavokActor::UShockActionFreezeHavokActor()
{
	ActionClassName = TEXT("ActionFreezeHavokActor");
	bFreeze = true;
	bActivateWhenUnfreezing = true;
}

void UShockActionFreezeHavokActor::Configure(FName InTargetLabel, bool bInFreeze)
{
	TargetLabel = InTargetLabel;
	bFreeze = bInFreeze;
}

bool UShockActionFreezeHavokActor::ApplyToActor(AActor* Target)
{
	if (Target == nullptr)
	{
		return false;
	}
	if (UPrimitiveComponent* Prim = Cast<UPrimitiveComponent>(Target->GetRootComponent()))
	{
		Prim->SetSimulatePhysics(!bFreeze);
	}
	bLastAppliedFreeze = bFreeze;
	return true;
}

int32 UShockActionFreezeHavokActor::ApplyInWorld(UWorld* World)
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
