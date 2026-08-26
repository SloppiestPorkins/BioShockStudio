#include "ShockActionDestroyActor.h"

#include "GameFramework/Actor.h"

UShockActionDestroyActor::UShockActionDestroyActor()
{
	ActionClassName = TEXT("ActionDestroyActor");
}

void UShockActionDestroyActor::Configure(FName InTargetLabel)
{
	TargetLabel = InTargetLabel;
}

bool UShockActionDestroyActor::DestroyTarget(AActor* Target)
{
	if (Target == nullptr)
	{
		return false;
	}
	LastDestroyedActorName = Target->GetFName();
	Target->Destroy();
	return true;
}
