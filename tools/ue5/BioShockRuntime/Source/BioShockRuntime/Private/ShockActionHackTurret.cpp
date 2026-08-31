#include "ShockActionHackTurret.h"

#include "ShockPlayer.h"
#include "ShockSecurityDevice.h"
#include "ShockTurret.h"

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

	AShockTurret* Turret = Cast<AShockTurret>(AShockSecurityDevice::FindByLabel(World, TurretLabel));
	if (Turret)
	{
		Turret->SetAllegiance(
			bSetHacked ? EShockDeviceAllegiance::Friendly : EShockDeviceAllegiance::Hostile);
	}

	Player->SetTurretHacked(TurretLabel, bSetHacked);
	return 1;
}

bool UShockActionHackTurret::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World) > 0;
}
