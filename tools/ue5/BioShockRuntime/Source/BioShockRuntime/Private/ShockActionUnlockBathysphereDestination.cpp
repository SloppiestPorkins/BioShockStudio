#include "ShockActionUnlockBathysphereDestination.h"

#include "ShockBathysphereStation.h"
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

	int32 Applied = 0;
	if (AShockBathysphereStation* Station = AShockBathysphereStation::FindByMapId(World, MapName))
	{
		Station->SetUnlocked(true);
		++Applied;
	}

	AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World);
	if (Player)
	{
		Player->UnlockBathysphereDestination(BathysphereSystem, MapName);
		++Applied;
	}
	return Applied;
}

bool UShockActionUnlockBathysphereDestination::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World) > 0;
}
