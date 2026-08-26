#include "ShockActionEnableOrDisableCascadingWaterVolume.h"

UShockActionEnableOrDisableCascadingWaterVolume::UShockActionEnableOrDisableCascadingWaterVolume()
{
	ActionClassName = TEXT("ActionEnableOrDisableCascadingWaterVolume");
}

void UShockActionEnableOrDisableCascadingWaterVolume::Configure(FName InVolume, bool bInEnable)
{
	VolumeLabel = InVolume;
	bEnableVolume = bInEnable;
}

bool UShockActionEnableOrDisableCascadingWaterVolume::RequestSet()
{
	if (VolumeLabel.IsNone())
	{
		return false;
	}
	LastVolumeLabel = VolumeLabel;
	return true;
}
