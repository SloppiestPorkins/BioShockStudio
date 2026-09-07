#include "ShockActionPlayAnimation.h"

#include "EngineUtils.h"
#include "GameFramework/Actor.h"
#include "ShockAnimatedProp.h"
#include "ShockDoor.h"

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

	if (AShockAnimatedProp* Prop = Cast<AShockAnimatedProp>(Target))
	{
		const bool bLoop = EndBehavior == EShockAnimEndBehavior::Loop;
		return Prop->PlayScriptedMotion(Animation, AnimationRate, bLoop);
	}
	return true;
}

int32 UShockActionPlayAnimation::PlayInWorld(UWorld* World)
{
	int32 Played = 0;
	if (!World || TargetLabel.IsNone())
	{
		return 0;
	}

	// LoadRoomDoor / Med_DoorAnim scripts drive their door via PlayAnimation(<clip>). Route the
	// exact clip name to the door: skeletal doors play that AnimSequence, swing doors fall back
	// to Open/CloseDoor on *OPEN* / *CLOS*.
	const FString AnimName = Animation.ToString();
	if (AnimName.Contains(TEXT("OPEN"), ESearchCase::IgnoreCase)
		|| AnimName.Contains(TEXT("CLOS"), ESearchCase::IgnoreCase))
	{
		if (AShockDoor* Door = AShockDoor::FindByLabel(World, TargetLabel))
		{
			if (Door->PlayDoorClip(Animation))
			{
				LastPlayedAnimation = Animation;
				LastPlayedActorName = Door->GetName();
				++Played;
			}
		}
	}

	const FString Want = TargetLabel.ToString();
	for (TActorIterator<AActor> It(World); It; ++It)
	{
		AActor* Actor = *It;
		if (!Actor)
		{
			continue;
		}
		if (Cast<AShockDoor>(Actor))
		{
			// Doors are handled by the FindByLabel OpenDoor path above.
			continue;
		}

		bool bMatch = false;
		if (const AShockAnimatedProp* Prop = Cast<AShockAnimatedProp>(Actor))
		{
			bMatch = Prop->PropLabel.ToString().Equals(Want, ESearchCase::CaseSensitive);
		}
#if WITH_EDITOR
		if (!bMatch)
		{
			bMatch = Actor->GetActorLabel().Equals(Want, ESearchCase::CaseSensitive);
		}
#endif
		if (bMatch && PlayOnActor(Actor))
		{
			++Played;
		}
	}
	return Played;
}

bool UShockActionPlayAnimation::ApplyInWorld(const FShockActionContext& Ctx)
{
	return PlayInWorld(Ctx.World) > 0;
}
