#include "ShockActionPlayAnimation.h"

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
