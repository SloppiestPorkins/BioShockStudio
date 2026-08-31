#include "ShockActionChangeLevel.h"

#include "ShockGameMode.h"

UShockActionChangeLevel::UShockActionChangeLevel()
{
	ActionClassName = TEXT("ActionChangeLevel");
}

void UShockActionChangeLevel::Configure(
	const FString& InMap,
	const FString& InStart,
	bool bInShowLoading,
	bool bInPersist)
{
	MapName = InMap;
	StartLocationLabel = InStart;
	bShowLoadingMessage = bInShowLoading;
	bPersist = bInPersist;
}

bool UShockActionChangeLevel::RequestChange()
{
	if (MapName.IsEmpty())
	{
		return false;
	}
	LastMapName = MapName;
	return true;
}

bool UShockActionChangeLevel::ApplyInWorld(const FShockActionContext& Ctx)
{
	if (!RequestChange() || !Ctx.World)
	{
		return false;
	}

	AShockGameMode* GameMode = Ctx.World->GetAuthGameMode<AShockGameMode>();
	if (!GameMode)
	{
		return false;
	}

	const FName StartLabel = StartLocationLabel.IsEmpty() ? NAME_None : FName(*StartLocationLabel);
	GameMode->TravelToLevel(MapName, StartLabel);
	return true;
}
