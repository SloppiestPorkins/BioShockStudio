#include "ShockActionFreezeHavokActor.h"

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
