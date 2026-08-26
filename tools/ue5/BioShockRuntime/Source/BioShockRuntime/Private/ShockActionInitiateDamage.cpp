#include "ShockActionInitiateDamage.h"

UShockActionInitiateDamage::UShockActionInitiateDamage()
{
	ActionClassName = TEXT("ActionInitiateDamage");
}

void UShockActionInitiateDamage::Configure(FName InDamager, FName InSource, FName InTarget, FName InDamageClass, float InVelocity)
{
	DamagerLabel = InDamager;
	SourceLabel = InSource;
	TargetLabel = InTarget;
	DamageClassName = InDamageClass;
	OverrideInitialVelocity = InVelocity;
}

bool UShockActionInitiateDamage::RequestDamage()
{
	if (TargetLabel.IsNone())
	{
		return false;
	}
	LastTargetLabel = TargetLabel;
	return true;
}
