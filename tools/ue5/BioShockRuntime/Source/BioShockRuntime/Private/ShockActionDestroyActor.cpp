#include "ShockActionDestroyActor.h"

#include "EngineUtils.h"
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

int32 UShockActionDestroyActor::DestroyInWorld(UWorld* World)
{
	int32 Destroyed = 0;
	if (!World || TargetLabel.IsNone())
	{
		return 0;
	}
	const FString Want = TargetLabel.ToString();
	TArray<AActor*> Matches;
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
			Matches.Add(Actor);
		}
#endif
	}
	for (AActor* Actor : Matches)
	{
		if (DestroyTarget(Actor))
		{
			++Destroyed;
		}
	}
	return Destroyed;
}
