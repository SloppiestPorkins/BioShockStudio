#include "ShockActionEnableOrDisableCascadingWaterVolume.h"

#include "GameFramework/Actor.h"
#include "ShockScriptReflection.h"
#include "ShockWaterVolume.h"

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

bool UShockActionEnableOrDisableCascadingWaterVolume::ApplyToActor(AActor* Target)
{
	AShockWaterVolume* Water = Cast<AShockWaterVolume>(Target);
	if (!Water)
	{
		return false;
	}
	Water->bCascading = bEnableVolume;
	Water->RefreshSurface();
	return true;
}

int32 UShockActionEnableOrDisableCascadingWaterVolume::ApplyInWorld(UWorld* World)
{
	if (!RequestSet() || !World)
	{
		return 0;
	}
	AActor* Target = ShockScriptReflection::ResolveTargetActor(World, VolumeLabel);
	if (!Target)
	{
		return 0;
	}
	return ApplyToActor(Target) ? 1 : 0;
}

bool UShockActionEnableOrDisableCascadingWaterVolume::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World) > 0;
}
