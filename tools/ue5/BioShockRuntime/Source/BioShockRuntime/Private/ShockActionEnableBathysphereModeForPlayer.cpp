#include "ShockActionEnableBathysphereModeForPlayer.h"

UShockActionEnableBathysphereModeForPlayer::UShockActionEnableBathysphereModeForPlayer()
{
	ActionClassName = TEXT("ActionEnableBathysphereModeForPlayer");
}

void UShockActionEnableBathysphereModeForPlayer::Configure(bool bInEnable)
{
	bEnableBathysphereMode = bInEnable;
}

bool UShockActionEnableBathysphereModeForPlayer::RequestSet()
{
	bLastEnableBathysphereMode = bEnableBathysphereMode;
	return true;
}
