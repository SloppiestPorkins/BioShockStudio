#include "ShockActionFadeVolumeOverride.h"

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
