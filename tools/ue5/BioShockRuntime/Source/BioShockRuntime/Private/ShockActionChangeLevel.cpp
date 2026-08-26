#include "ShockActionChangeLevel.h"

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
