#include "ShockActionDealShockingDamageInRadius.h"

UShockActionDealShockingDamageInRadius::UShockActionDealShockingDamageInRadius()
{
	ActionClassName = TEXT("ActionDealShockingDamageInRadius");
	DamageAmount = 100.0f;
	DamageType = 24;
	InnerRadius = 1024;
	OuterRadius = 1024;
	MaxNumBolts = 5;
	EffectTime = 3.0f;
}

void UShockActionDealShockingDamageInRadius::Configure(
	FName InSource,
	float InDamage,
	int32 InDamageType,
	int32 InInner,
	int32 InOuter,
	int32 InMaxNumBolts,
	FName InEffectClass,
	float InEffectTime,
	FVector2D InNewBeamDelay)
{
	SourceActorLabel = InSource;
	DamageAmount = InDamage;
	DamageType = InDamageType;
	InnerRadius = InInner;
	OuterRadius = InOuter;
	MaxNumBolts = InMaxNumBolts;
	EffectClassName = InEffectClass;
	EffectTime = InEffectTime;
	NewBeamDelay = InNewBeamDelay;
}

bool UShockActionDealShockingDamageInRadius::RequestDeal()
{
	if (SourceActorLabel.IsNone())
	{
		return false;
	}
	LastSourceActorLabel = SourceActorLabel;
	return true;
}
