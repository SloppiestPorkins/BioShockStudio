#include "ShockActionApplyImpulse.h"

#include "Components/PrimitiveComponent.h"
#include "EngineUtils.h"
#include "GameFramework/Actor.h"

UShockActionApplyImpulse::UShockActionApplyImpulse()
{
	ActionClassName = TEXT("ActionApplyImpulse");
}

void UShockActionApplyImpulse::Configure(FName InTarget, FVector InVelocity, FName InBone)
{
	Target = InTarget;
	Velocity = InVelocity;
	BoneName = InBone;
}

bool UShockActionApplyImpulse::RequestApply()
{
	if (Target.IsNone())
	{
		return false;
	}
	LastTarget = Target;
	return true;
}

int32 UShockActionApplyImpulse::ApplyInWorld(UWorld* World)
{
	int32 Applied = 0;
	if (!RequestApply() || !World || Velocity.IsNearlyZero())
	{
		return 0;
	}
	const FString Want = Target.ToString();
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
			Prim->AddImpulse(Velocity, NAME_None, true);
			++Applied;
		}
#endif
	}
	return Applied;
}
