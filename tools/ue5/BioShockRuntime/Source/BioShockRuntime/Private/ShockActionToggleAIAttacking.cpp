#include "ShockActionToggleAIAttacking.h"

#include "BaseShockAI.h"

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

int32 UShockActionToggleAIAttacking::ApplyInWorld(UWorld* World)
{
	if (!RequestToggle())
	{
		return 0;
	}
	int32 Applied = 0;
	for (ABaseShockAI* AI : ABaseShockAI::CollectLabeled(World, AILabel))
	{
		AI->bCanAttack = bCanAttack;
		++Applied;
	}
	return Applied;
}
