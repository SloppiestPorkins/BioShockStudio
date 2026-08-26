#include "ShockGameMode.h"
#include "ShockPlayer.h"

AShockGameMode::AShockGameMode()
{
	DefaultPawnClass = AShockPlayer::StaticClass();
}
