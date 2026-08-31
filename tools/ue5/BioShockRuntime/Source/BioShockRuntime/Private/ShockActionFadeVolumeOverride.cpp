#include "ShockActionFadeVolumeOverride.h"

#include "ShockPlayer.h"

UShockActionFadeVolumeOverride::UShockActionFadeVolumeOverride()
{
	ActionClassName = TEXT("ActionFadeVolumeOverride");
}

void UShockActionFadeVolumeOverride::Configure(float InVolume, float InDuration)
{
	Volume = InVolume;
	Duration = InDuration;
}

bool UShockActionFadeVolumeOverride::RequestFade()
{
	LastVolume = Volume;
	return true;
}

int32 UShockActionFadeVolumeOverride::ApplyInWorld(UWorld* World)
{
	if (!RequestFade())
	{
		return 0;
	}
	AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World);
	if (!Player)
	{
		return 0;
	}
	Player->SetFadeVolumeOverride(Volume, Duration);
	return 1;
}

bool UShockActionFadeVolumeOverride::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World) > 0;
}
