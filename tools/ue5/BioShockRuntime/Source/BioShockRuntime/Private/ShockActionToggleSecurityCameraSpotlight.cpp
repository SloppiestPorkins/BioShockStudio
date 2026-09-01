#include "ShockActionToggleSecurityCameraSpotlight.h"

#include "Engine/World.h"
#include "ShockSecurityCamera.h"
#include "ShockSecurityDevice.h"

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

int32 UShockActionToggleSecurityCameraSpotlight::ApplyInWorld(UWorld* World)
{
	if (!RequestToggle() || !World)
	{
		return 0;
	}

	AShockSecurityCamera* Camera = Cast<AShockSecurityCamera>(
		AShockSecurityDevice::FindByLabel(World, CameraLabel));
	if (!Camera)
	{
		return 0;
	}

	Camera->SetSpotlightEnabled(bSpotlightOn);
	return 1;
}

bool UShockActionToggleSecurityCameraSpotlight::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World) > 0;
}
