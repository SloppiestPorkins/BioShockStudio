#include "ShockActionActivateSecurityBot.h"

UShockActionActivateSecurityBot::UShockActionActivateSecurityBot()
{
	ActionClassName = TEXT("ActionActivateSecurityBot");
}

void UShockActionActivateSecurityBot::Configure(FName InPawn, FName InBot)
{
	PawnLabel = InPawn;
	BotLabel = InBot;
}

bool UShockActionActivateSecurityBot::RequestActivate()
{
	if (PawnLabel.IsNone() || BotLabel.IsNone())
	{
		return false;
	}
	LastBotLabel = BotLabel;
	return true;
}
