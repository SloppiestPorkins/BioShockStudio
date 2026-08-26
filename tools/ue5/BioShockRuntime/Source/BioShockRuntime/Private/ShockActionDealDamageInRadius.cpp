#include "ShockActionDealDamageInRadius.h"

UShockActionDealDamageInRadius::UShockActionDealDamageInRadius()
{
	ActionClassName = TEXT("ActionDealDamageInRadius");
	DamageAmount = 100.0f;
	DamageType = 8;
	InnerRadius = 256;
	OuterRadius = 256;
}

void UShockActionDealDamageInRadius::Configure(FName InSource, float InDamage, int32 InInner, int32 InOuter)
{
	SourceActorLabel = InSource;
	DamageAmount = InDamage;
	InnerRadius = InInner;
	OuterRadius = InOuter;
}

bool UShockActionDealDamageInRadius::RequestDeal()
{
	if (SourceActorLabel.IsNone())
	{
		return false;
	}
	LastSourceActorLabel = SourceActorLabel;
	return true;
}
