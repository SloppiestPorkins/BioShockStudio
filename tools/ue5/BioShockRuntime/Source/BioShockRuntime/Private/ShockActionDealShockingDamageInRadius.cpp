#include "ShockActionDealShockingDamageInRadius.h"

#include "ShockDamageLibrary.h"

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

int32 UShockActionDealShockingDamageInRadius::ApplyInWorld(UWorld* World)
{
	if (!RequestDeal() || !World || DamageAmount <= 0.0f || OuterRadius <= 0)
	{
		return 0;
	}
	AActor* Source = UShockDamageLibrary::FindActorByLabel(World, SourceActorLabel);
	if (!Source)
	{
		return 0;
	}
	const FName TypeName = DamageType != 0 ? FName(*FString::Printf(TEXT("DamageType_%d"), DamageType)) : NAME_None;
	return UShockDamageLibrary::ApplyRadialDamage(
		World,
		Source->GetActorLocation(),
		static_cast<float>(OuterRadius),
		DamageAmount,
		Source,
		TypeName,
		static_cast<float>(InnerRadius));
}
