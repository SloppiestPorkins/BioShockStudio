#include "ShockActionRagdoll.h"

#include "Components/PrimitiveComponent.h"
#include "EngineUtils.h"
#include "GameFramework/Actor.h"

UShockActionRagdoll::UShockActionRagdoll()
{
	ActionClassName = TEXT("ActionRagdoll");
}

void UShockActionRagdoll::Configure(FName InAI, bool bInRelative, FVector InImpulse, float InMomentum)
{
	AILabel = InAI;
	bRelativeToAIRotation = bInRelative;
	HitImpulseDirection = InImpulse;
	HitMomentumImparted = InMomentum;
}

bool UShockActionRagdoll::RequestRagdoll()
{
	if (AILabel.IsNone())
	{
		return false;
	}
	LastAILabel = AILabel;
	return true;
}

int32 UShockActionRagdoll::ApplyInWorld(UWorld* World)
{
	int32 Applied = 0;
	if (!RequestRagdoll() || !World)
	{
		return 0;
	}
	const FString Want = AILabel.ToString();
	const FVector Impulse = HitImpulseDirection * HitMomentumImparted;
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
		if (UPrimitiveComponent* Prim = Cast<UPrimitiveComponent>(Actor->GetRootComponent()))
		{
			Prim->SetSimulatePhysics(true);
			if (!Impulse.IsNearlyZero())
			{
				Prim->AddImpulse(Impulse, NAME_None, true);
			}
			++Applied;
		}
#endif
	}
	return Applied;
}
