#include "ShockActionDealDamage.h"

#include "ShockDamageLibrary.h"
#include "ShockPawn.h"

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

int32 UShockActionDealDamage::ApplyInWorld(UWorld* World)
{
	if (!RequestDamage() || !World)
	{
		return 0;
	}
	if (DamageChance < 1.0f && FMath::FRand() > DamageChance)
	{
		return 0;
	}
	int32 Applied = 0;
	for (AShockPawn* Pawn : AShockPawn::CollectLabeled(World, TargetLabel))
	{
		if (UShockDamageLibrary::ApplyDamage(Pawn, DamageAmount, nullptr, NAME_None) > 0.0f)
		{
			LastTargetLabel = TargetLabel;
			LastDamageAmount = DamageAmount;
			++Applied;
		}
	}
	return Applied;
}

bool UShockActionDealDamage::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World) > 0;
}
