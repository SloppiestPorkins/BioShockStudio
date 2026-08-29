#include "ShockActionToggleAIWeaponVisibility.h"

#include "BaseShockAI.h"

UShockActionToggleAIWeaponVisibility::UShockActionToggleAIWeaponVisibility()
{
	ActionClassName = TEXT("ActionToggleAIWeaponVisibility");
}

void UShockActionToggleAIWeaponVisibility::Configure(FName InAILabel, bool bInShow)
{
	AILabel = InAILabel;
	bShowWeapon = bInShow;
}

bool UShockActionToggleAIWeaponVisibility::RequestToggle()
{
	if (AILabel.IsNone())
	{
		return false;
	}
	LastAILabel = AILabel;
	return true;
}

int32 UShockActionToggleAIWeaponVisibility::ApplyInWorld(UWorld* World)
{
	if (!RequestToggle())
	{
		return 0;
	}
	int32 Applied = 0;
	for (ABaseShockAI* AI : ABaseShockAI::CollectLabeled(World, AILabel))
	{
		AI->SetWeaponVisible(bShowWeapon);
		++Applied;
	}
	return Applied;
}
