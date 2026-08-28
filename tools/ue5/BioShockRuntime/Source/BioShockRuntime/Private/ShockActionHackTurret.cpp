#include "ShockActionHackTurret.h"

#include "ShockPlayer.h"

UShockActionHackTurret::UShockActionHackTurret()
{
	ActionClassName = TEXT("ActionHackTurret");
}

void UShockActionHackTurret::Configure(FName InTurret, bool bInHacked)
{
	TurretLabel = InTurret;
	bSetHacked = bInHacked;
}

bool UShockActionHackTurret::RequestHack()
{
	if (TurretLabel.IsNone())
	{
		return false;
	}
	LastTurretLabel = TurretLabel;
	return true;
}

int32 UShockActionHackTurret::ApplyInWorld(UWorld* World)
{
	if (!RequestHack() || !World)
	{
		return 0;
	}
	AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World);
	if (!Player)
	{
		return 0;
	}
	Player->SetTurretHacked(TurretLabel, bSetHacked);
	return 1;
}
