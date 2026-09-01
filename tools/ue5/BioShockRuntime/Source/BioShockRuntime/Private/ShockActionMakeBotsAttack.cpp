#include "ShockActionMakeBotsAttack.h"

#include "Engine/World.h"
#include "ShockSecuritySubsystem.h"

UShockActionMakeBotsAttack::UShockActionMakeBotsAttack()
{
	ActionClassName = TEXT("ActionMakeBotsAttack");
}

void UShockActionMakeBotsAttack::Configure(FName InController, FName InAttackee)
{
	ControllerLabel = InController;
	AttackeeLabel = InAttackee;
}

bool UShockActionMakeBotsAttack::RequestAttack()
{
	if (ControllerLabel.IsNone() || AttackeeLabel.IsNone())
	{
		return false;
	}
	LastControllerLabel = ControllerLabel;
	return true;
}

int32 UShockActionMakeBotsAttack::ApplyInWorld(UWorld* World)
{
	if (!RequestAttack() || !World)
	{
		return 0;
	}

	if (UShockSecuritySubsystem* Security = UShockSecuritySubsystem::Get(World))
	{
		return Security->CommandBotsAttackTarget(AttackeeLabel) ? 1 : 0;
	}
	return 0;
}

bool UShockActionMakeBotsAttack::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World) > 0;
}
