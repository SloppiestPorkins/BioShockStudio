#include "ShockActionToggleAIAttacking.h"

UShockActionToggleAIAttacking::UShockActionToggleAIAttacking()
{
	ActionClassName = TEXT("ActionToggleAIAttacking");
}

void UShockActionToggleAIAttacking::Configure(FName InAILabel, bool bInCanAttack)
{
	AILabel = InAILabel;
	bCanAttack = bInCanAttack;
}

bool UShockActionToggleAIAttacking::RequestToggle()
{
	if (AILabel.IsNone())
	{
		return false;
	}
	LastAILabel = AILabel;
	return true;
}
