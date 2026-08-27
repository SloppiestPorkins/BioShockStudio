#include "ShockActionPlayAnimation.h"

#include "EngineUtils.h"
#include "GameFramework/Actor.h"

UShockActionPlayAnimation::UShockActionPlayAnimation()
{
	ActionClassName = TEXT("ActionPlayAnimation");
	TargetLabel = FName(TEXT("UNSPECIFIED"));
	AnimationRate = 1.0f;
	bOnlyPlayOnAlivePawns = true;
}

void UShockActionPlayAnimation::Configure(
	FName InTargetLabel,
	FName InAnimation,
	float InRate,
	int32 InChannel)
{
	TargetLabel = InTargetLabel;
	Animation = InAnimation;
	AnimationRate = InRate;
	Channel = InChannel;
}

bool UShockActionPlayAnimation::PlayOnActor(AActor* Target)
{
	if (Target == nullptr || Animation.IsNone())
	{
		return false;
	}
	LastPlayedAnimation = Animation;
	LastPlayedActorName = Target->GetName();
	return true;
}

int32 UShockActionPlayAnimation::PlayInWorld(UWorld* World)
{
	int32 Played = 0;
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
		if (PlayOnActor(Actor))
		{
			++Played;
		}
#endif
	}
	return Played;
}
