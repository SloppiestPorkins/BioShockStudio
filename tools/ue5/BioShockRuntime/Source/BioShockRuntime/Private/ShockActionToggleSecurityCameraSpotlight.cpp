#include "ShockActionToggleSecurityCameraSpotlight.h"

UShockActionToggleSecurityCameraSpotlight::UShockActionToggleSecurityCameraSpotlight()
{
	ActionClassName = TEXT("ActionToggleSecurityCameraSpotlight");
}

void UShockActionToggleSecurityCameraSpotlight::Configure(FName InCamera, bool bInOn)
{
	CameraLabel = InCamera;
	bSpotlightOn = bInOn;
}

bool UShockActionToggleSecurityCameraSpotlight::RequestToggle()
{
	if (CameraLabel.IsNone())
	{
		return false;
	}
	LastCameraLabel = CameraLabel;
	return true;
}
