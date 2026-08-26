#include "ShockActionMakeBotsAttack.h"

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
