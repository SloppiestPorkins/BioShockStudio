#include "ShockActionEnableOrDisableLevelSwitching.h"

#include "ShockPlayer.h"

UShockActionEnableOrDisableLevelSwitching::UShockActionEnableOrDisableLevelSwitching()
{
	ActionClassName = TEXT("ActionEnableOrDisableLevelSwitching");
}

void UShockActionEnableOrDisableLevelSwitching::Configure(bool bInDisable)
{
	bDisableLevelSwitching = bInDisable;
}

bool UShockActionEnableOrDisableLevelSwitching::RequestSet()
{
	bLastDisableLevelSwitching = bDisableLevelSwitching;
	return true;
}

int32 UShockActionEnableOrDisableLevelSwitching::ApplyInWorld(UWorld* World)
{
	if (!RequestSet() || !World)
	{
		return 0;
	}
	AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World);
	if (!Player)
	{
		return 0;
	}
	Player->SetLevelSwitchingDisabled(bDisableLevelSwitching);
	return 1;
}
