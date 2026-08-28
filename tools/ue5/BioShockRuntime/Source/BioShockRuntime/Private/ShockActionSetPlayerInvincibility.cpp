#include "ShockActionSetPlayerInvincibility.h"

#include "ShockPlayer.h"

UShockActionSetPlayerInvincibility::UShockActionSetPlayerInvincibility()
{
	ActionClassName = TEXT("ActionSetPlayerInvincibility");
	bInvincible = true;
}

void UShockActionSetPlayerInvincibility::Configure(bool bInInvincible)
{
	bInvincible = bInInvincible;
}

bool UShockActionSetPlayerInvincibility::RequestSet()
{
	bLastInvincible = bInvincible;
	return true;
}

int32 UShockActionSetPlayerInvincibility::ApplyInWorld(UWorld* World)
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
	Player->SetInvincible(bInvincible);
	return 1;
}
