#include "ShockActionCinematicFadeView.h"

UShockActionCinematicFadeView::UShockActionCinematicFadeView()
{
	ActionClassName = TEXT("ActionCinematicFadeView");
	FadeAlphaEnd = 1.0f;
	Duration = 2.0f;
	bIsGameCritical = false;
}

void UShockActionCinematicFadeView::Configure(float InAlphaStart, float InAlphaEnd, float InDuration, float InHold)
{
	FadeAlphaStart = InAlphaStart;
	FadeAlphaEnd = InAlphaEnd;
	Duration = InDuration;
	HoldDuration = InHold;
}

bool UShockActionCinematicFadeView::RequestFade()
{
	if (Duration < 0.0f)
	{
		return false;
	}
	LastRequestedDuration = Duration;
	return true;
}

bool UShockActionCinematicFadeView::ApplyInWorld(const FShockActionContext& Ctx)
{
	(void)Ctx;
	return RequestFade();
}

void UShockActionCinematicFadeView::PrepareWait(float WorldTimeSeconds)
{
	const float Total = FMath::Max(0.0f, Duration) + FMath::Max(0.0f, HoldDuration);
	WakeAtTime = WorldTimeSeconds + Total;
}

bool UShockActionCinematicFadeView::IsReady(float WorldTimeSeconds) const
{
	return WakeAtTime >= 0.0f && WorldTimeSeconds >= WakeAtTime;
}
