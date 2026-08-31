#include "ShockActionInitiateDamage.h"

#include "ShockDamageLibrary.h"
#include "ShockPawn.h"

namespace
{
	/** Stand-in until damage-class → amount lookup exists. */
	constexpr float DefaultInitiateDamageAmount = 25.0f;
}

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

int32 UShockActionInitiateDamage::ApplyInWorld(UWorld* World)
{
	LastAppliedCount = 0;
	if (!RequestDamage() || !World)
	{
		return 0;
	}
	AActor* Instigator = UShockDamageLibrary::FindActorByLabel(World, DamagerLabel);
	if (!Instigator && !SourceLabel.IsNone())
	{
		Instigator = UShockDamageLibrary::FindActorByLabel(World, SourceLabel);
	}
	for (AShockPawn* Pawn : AShockPawn::CollectLabeled(World, TargetLabel))
	{
		if (UShockDamageLibrary::ApplyDamage(Pawn, DefaultInitiateDamageAmount, Instigator, DamageClassName) > 0.0f)
		{
			++LastAppliedCount;
		}
	}
	return LastAppliedCount;
}

bool UShockActionInitiateDamage::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World) > 0;
}
