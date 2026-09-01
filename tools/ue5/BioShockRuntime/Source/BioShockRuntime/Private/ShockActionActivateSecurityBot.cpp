#include "ShockActionActivateSecurityBot.h"

#include "Engine/World.h"
#include "ShockSecuritySubsystem.h"

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

int32 UShockActionActivateSecurityBot::ApplyInWorld(UWorld* World)
{
	if (!RequestActivate() || !World)
	{
		return 0;
	}

	if (UShockSecuritySubsystem* Security = UShockSecuritySubsystem::Get(World))
	{
		return Security->ActivateBotByLabel(BotLabel, PawnLabel) ? 1 : 0;
	}
	return 0;
}

bool UShockActionActivateSecurityBot::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World) > 0;
}
