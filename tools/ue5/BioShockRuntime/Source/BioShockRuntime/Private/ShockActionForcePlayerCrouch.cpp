#include "ShockActionForcePlayerCrouch.h"

#include "ShockPlayer.h"

UShockActionForcePlayerCrouch::UShockActionForcePlayerCrouch()
{
	ActionClassName = TEXT("ActionForcePlayerCrouch");
}

void UShockActionForcePlayerCrouch::Configure(bool bInShouldCrouch)
{
	bShouldCrouch = bInShouldCrouch;
}

bool UShockActionForcePlayerCrouch::RequestCrouch()
{
	bLastShouldCrouch = bShouldCrouch;
	return true;
}

int32 UShockActionForcePlayerCrouch::ApplyInWorld(UWorld* World)
{
	if (!RequestCrouch())
	{
		return 0;
	}
	AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World);
	if (!Player)
	{
		return 0;
	}
	Player->SetForcedCrouch(bShouldCrouch);
	return 1;
}
