#include "ShockActionEnableOrDisableLevelSaving.h"

#include "ShockPlayer.h"

UShockActionEnableOrDisableLevelSaving::UShockActionEnableOrDisableLevelSaving()
{
	ActionClassName = TEXT("ActionEnableOrDisableLevelSaving");
}

void UShockActionEnableOrDisableLevelSaving::Configure(bool bInDisable)
{
	bDisableLevelSaving = bInDisable;
}

bool UShockActionEnableOrDisableLevelSaving::RequestSet()
{
	bLastDisableLevelSaving = bDisableLevelSaving;
	return true;
}

int32 UShockActionEnableOrDisableLevelSaving::ApplyInWorld(UWorld* World)
{
	if (!RequestSet())
	{
		return 0;
	}
	AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World);
	if (!Player)
	{
		return 0;
	}
	Player->SetLevelSavingDisabled(bDisableLevelSaving);
	return 1;
}
