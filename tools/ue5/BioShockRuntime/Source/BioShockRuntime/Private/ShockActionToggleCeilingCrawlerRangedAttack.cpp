#include "ShockActionToggleCeilingCrawlerRangedAttack.h"

UShockActionToggleCeilingCrawlerRangedAttack::UShockActionToggleCeilingCrawlerRangedAttack()
{
	ActionClassName = TEXT("ActionToggleCeilingCrawlerRangedAttack");
}

void UShockActionToggleCeilingCrawlerRangedAttack::Configure(FName InLabel, bool bInEnable)
{
	CeilingCrawlerLabel = InLabel;
	bEnableRangedAttack = bInEnable;
}

bool UShockActionToggleCeilingCrawlerRangedAttack::RequestToggle()
{
	if (CeilingCrawlerLabel.IsNone())
	{
		return false;
	}
	LastCeilingCrawlerLabel = CeilingCrawlerLabel;
	return true;
}
