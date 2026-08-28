#include "ShockActionSetMovableSpotlightTarget.h"

#include "ShockPlayer.h"

UShockActionSetMovableSpotlightTarget::UShockActionSetMovableSpotlightTarget()
{
	ActionClassName = TEXT("ActionSetMovableSpotlightTarget");
}

void UShockActionSetMovableSpotlightTarget::Configure(FName InSpotlight, FName InTarget)
{
	SpotlightLabel = InSpotlight;
	TargetActorLabel = InTarget;
}

bool UShockActionSetMovableSpotlightTarget::RequestSetTarget()
{
	if (SpotlightLabel.IsNone())
	{
		return false;
	}
	LastSpotlightLabel = SpotlightLabel;
	LastTargetActorLabel = TargetActorLabel;
	return true;
}

int32 UShockActionSetMovableSpotlightTarget::ApplyInWorld(UWorld* World)
{
	if (!RequestSetTarget() || !World)
	{
		return 0;
	}
	AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World);
	if (!Player)
	{
		return 0;
	}
	Player->SetSpotlightTarget(SpotlightLabel, TargetActorLabel);
	return 1;
}
