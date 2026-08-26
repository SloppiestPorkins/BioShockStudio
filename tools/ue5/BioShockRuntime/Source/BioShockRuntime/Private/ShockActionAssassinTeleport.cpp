#include "ShockActionAssassinTeleport.h"

UShockActionAssassinTeleport::UShockActionAssassinTeleport()
{
	ActionClassName = TEXT("ActionAssassinTeleport");
}

void UShockActionAssassinTeleport::Configure(
	FName InAssassin,
	FName InTeleport,
	FName InRotation,
	bool bInEffects,
	bool bInSkipEther)
{
	AssassinLabel = InAssassin;
	TeleportLabel = InTeleport;
	TeleportRotationLabel = InRotation;
	bUseTeleportOutEffects = bInEffects;
	bSkipEtherTime = bInSkipEther;
}

bool UShockActionAssassinTeleport::RequestTeleport()
{
	if (AssassinLabel.IsNone() || TeleportLabel.IsNone())
	{
		return false;
	}
	LastAssassinLabel = AssassinLabel;
	return true;
}
