#include "ShockActionDisplayMapHUDRegion.h"

#include "ShockPlayer.h"

UShockActionDisplayMapHUDRegion::UShockActionDisplayMapHUDRegion()
{
	ActionClassName = TEXT("ActionDisplayMapHUDRegion");
}

void UShockActionDisplayMapHUDRegion::Configure(const FString& InDescription)
{
	MapHUDRegionDescription = InDescription;
}

bool UShockActionDisplayMapHUDRegion::RequestDisplay()
{
	bRequested = true;
	return true;
}

int32 UShockActionDisplayMapHUDRegion::ApplyInWorld(UWorld* World)
{
	if (!RequestDisplay() || !World)
	{
		return 0;
	}
	AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World);
	if (!Player)
	{
		return 0;
	}
	Player->SetMapHUDRegion(MapHUDRegionDescription);
	return 1;
}
