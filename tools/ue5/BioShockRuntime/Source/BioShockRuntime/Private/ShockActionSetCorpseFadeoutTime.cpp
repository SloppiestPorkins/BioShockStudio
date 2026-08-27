#include "ShockActionSetCorpseFadeoutTime.h"

UShockActionSetCorpseFadeoutTime::UShockActionSetCorpseFadeoutTime()
{
	ActionClassName = TEXT("ActionSetCorpseFadeoutTime");
	FadeOutDuration = 3.f;
}
void UShockActionSetCorpseFadeoutTime::Configure(FName InLabel, float InDuration)
{
	AILabel = InLabel;
	FadeOutDuration = InDuration;
}
bool UShockActionSetCorpseFadeoutTime::RequestFade()
{
	if (AILabel.IsNone()) return false;
	return FadeOutDuration >= 0.f;
}
