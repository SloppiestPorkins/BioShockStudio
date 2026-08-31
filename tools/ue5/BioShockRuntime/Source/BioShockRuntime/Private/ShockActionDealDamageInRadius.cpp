#include "ShockActionDealDamageInRadius.h"

#include "ShockDamageLibrary.h"

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

int32 UShockActionDealDamageInRadius::ApplyInWorld(UWorld* World)
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

bool UShockActionDealDamageInRadius::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World) > 0;
}
