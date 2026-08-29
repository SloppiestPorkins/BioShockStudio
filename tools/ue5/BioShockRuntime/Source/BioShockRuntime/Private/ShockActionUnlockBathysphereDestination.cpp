#include "ShockActionUnlockBathysphereDestination.h"

#include "ShockPlayer.h"

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

int32 UShockActionUnlockBathysphereDestination::ApplyInWorld(UWorld* World)
{
	if (!RequestUnlock() || !World)
	{
		return 0;
	}
	AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World);
	if (!Player)
	{
		return 0;
	}
	Player->UnlockBathysphereDestination(BathysphereSystem, MapName);
	return 1;
}
