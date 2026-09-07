#include "ShockActionChangeAnimationRate.h"

#include "EngineUtils.h"
#include "GameFramework/Actor.h"
#include "ShockAnimatedProp.h"

UShockActionChangeAnimationRate::UShockActionChangeAnimationRate()
{
	ActionClassName = TEXT("ActionChangeAnimationRate");
	TargetLabel = TEXT("UNSPECIFIED");
	TargetAnimationRate = 1.0f;
}

void UShockActionChangeAnimationRate::Configure(FName InTarget, FName InAnim, float InRate, float InTime)
{
	TargetLabel = InTarget;
	TargetAnimationName = InAnim;
	TargetAnimationRate = InRate;
	RateChangeTime = InTime;
}

bool UShockActionChangeAnimationRate::RequestChange()
{
	if (TargetLabel.IsNone())
	{
		return false;
	}
	LastTargetLabel = TargetLabel;
	LastAppliedRate = TargetAnimationRate;
	return true;
}

int32 UShockActionChangeAnimationRate::ApplyRateInWorld(UWorld* World)
{
	if (!RequestChange() || !World)
	{
		return 0;
	}

	int32 Applied = 0;
	const FString Want = TargetLabel.ToString();
	for (TActorIterator<AShockAnimatedProp> It(World); It; ++It)
	{
		AShockAnimatedProp* Prop = *It;
		if (!Prop)
		{
			continue;
		}

		bool bMatch = Prop->PropLabel.ToString().Equals(Want, ESearchCase::CaseSensitive);
#if WITH_EDITOR
		if (!bMatch)
		{
			bMatch = Prop->GetActorLabel().Equals(Want, ESearchCase::CaseSensitive);
		}
#endif
		if (!bMatch)
		{
			continue;
		}

		Prop->SetSpinRateScale(TargetAnimationRate);
		Prop->SetMotionRateScale(TargetAnimationRate);
		++Applied;
	}
	return Applied;
}

bool UShockActionChangeAnimationRate::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyRateInWorld(Ctx.World) > 0;
}
