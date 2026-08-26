#include "ShockActionUnlockBathysphereDestination.h"

UShockActionUnlockBathysphereDestination::UShockActionUnlockBathysphereDestination()
{
	ActionClassName = TEXT("ActionUnlockBathysphereDestination");
	BathysphereSystem = TEXT("BioshockBathyspheres");
}

void UShockActionUnlockBathysphereDestination::Configure(FName InMap, FName InSystem)
{
	MapName = InMap;
	BathysphereSystem = InSystem;
}

bool UShockActionUnlockBathysphereDestination::RequestUnlock()
{
	if (MapName.IsNone())
	{
		return false;
	}
	LastMapName = MapName;
	return true;
}
