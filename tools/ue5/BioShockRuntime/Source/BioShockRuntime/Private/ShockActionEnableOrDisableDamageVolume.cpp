#include "ShockActionEnableOrDisableDamageVolume.h"

UShockActionEnableOrDisableDamageVolume::UShockActionEnableOrDisableDamageVolume()
{
	ActionClassName = TEXT("ActionEnableOrDisableDamageVolume");
}

void UShockActionEnableOrDisableDamageVolume::Configure(FName InVolume, bool bInEnable)
{
	VolumeLabel = InVolume;
	bEnableVolume = bInEnable;
}

bool UShockActionEnableOrDisableDamageVolume::RequestSet()
{
	if (VolumeLabel.IsNone())
	{
		return false;
	}
	LastVolumeLabel = VolumeLabel;
	return true;
}
