#include "ShockActionDealDamage.h"

#include "EngineUtils.h"
#include "GameFramework/Actor.h"
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
	int32 Applied = 0;
	if (!World || TargetLabel.IsNone() || DamageAmount <= 0.0f)
	{
		return 0;
	}
	if (DamageChance < 1.0f && FMath::FRand() > DamageChance)
	{
		return 0;
	}
	const FString Want = TargetLabel.ToString();
	for (TActorIterator<AActor> It(World); It; ++It)
	{
		AActor* Actor = *It;
		if (!Actor)
		{
			continue;
		}
#if WITH_EDITOR
		if (!Actor->GetActorLabel().Equals(Want, ESearchCase::CaseSensitive))
		{
			continue;
		}
		if (AShockPawn* Pawn = Cast<AShockPawn>(Actor))
		{
			Pawn->EnsureHealthInitialized();
			Pawn->ApplyAuthoredDamage(DamageAmount);
			LastTargetLabel = TargetLabel;
			LastDamageAmount = DamageAmount;
			++Applied;
		}
#endif
	}
	return Applied;
}
