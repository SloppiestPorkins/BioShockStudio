#include "ShockPlayer.h"

AShockPlayer::AShockPlayer()
{
	SchemaClassName = TEXT("ShockPlayer");
	bUseControllerRotationYaw = true;
	AutoPossessPlayer = EAutoReceiveInput::Disabled;
}
