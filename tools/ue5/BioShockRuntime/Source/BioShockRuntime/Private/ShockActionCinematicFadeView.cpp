#include "ShockActionCinematicFadeView.h"

UShockActionCinematicFadeView::UShockActionCinematicFadeView()
{
	ActionClassName = TEXT("ActionCinematicFadeView");
	FadeAlphaEnd = 1.0f;
	Duration = 2.0f;
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
