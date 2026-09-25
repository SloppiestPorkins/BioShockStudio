#include "ShockActionDestroyActor.h"

#include "ShockScriptReflection.h"

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

int32 UShockActionDestroyActor::DestroyInWorld(UWorld* World)
{
	int32 Destroyed = 0;
	if (!World || TargetLabel.IsNone())
	{
		return 0;
	}
	TArray<AActor*> Matches = ShockScriptReflection::CollectActorsByLabel(World, TargetLabel);
	for (AActor* Actor : Matches)
	{
		if (DestroyTarget(Actor))
		{
			++Destroyed;
		}
	}
	return Destroyed;
}

bool UShockActionDestroyActor::ApplyInWorld(const FShockActionContext& Ctx)
{
	return DestroyInWorld(Ctx.World) > 0;
}
