#include "ShockActionDisablePlayerMovement.h"

#include "ShockPlayer.h"

UShockActionDisablePlayerMovement::UShockActionDisablePlayerMovement()
{
	ActionClassName = TEXT("ActionDisablePlayerMovement");
}

void UShockActionDisablePlayerMovement::Configure(bool bInDisable)
{
	bDisableMovement = bInDisable;
}

bool UShockActionDisablePlayerMovement::RequestSet()
{
	bLastDisableMovement = bDisableMovement;
	return true;
}

int32 UShockActionDisablePlayerMovement::ApplyInWorld(UWorld* World)
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
	Player->SetMovementDisabled(bDisableMovement);
	return 1;
}
