#include "ShockActionDealDamage.h"

UShockActionDealDamage::UShockActionDealDamage()
{
	ActionClassName = TEXT("ActionDealDamage");
	DamageAmount = 100.0f;
	DamageChance = 1.0f;
}

void UShockActionDealDamage::Configure(FName InTargetLabel, float InDamageAmount, float InDamageChance)
{
	TargetLabel = InTargetLabel;
	DamageAmount = InDamageAmount;
	DamageChance = InDamageChance;
}

bool UShockActionDealDamage::RequestDamage()
{
	if (TargetLabel.IsNone() || DamageAmount <= 0.0f)
	{
		return false;
	}
	LastTargetLabel = TargetLabel;
	LastDamageAmount = DamageAmount;
	return true;
}
