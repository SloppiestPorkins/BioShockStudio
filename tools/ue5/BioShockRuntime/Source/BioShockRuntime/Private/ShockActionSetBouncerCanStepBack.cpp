#include "ShockActionSetBouncerCanStepBack.h"

UShockActionSetBouncerCanStepBack::UShockActionSetBouncerCanStepBack()
{
	ActionClassName = TEXT("ActionSetBouncerCanStepBack");
}
void UShockActionSetBouncerCanStepBack::Configure(FName InLabel, bool bInCanStepBack)
{
	BouncerLabel = InLabel;
	bCanStepBack = bInCanStepBack;
}
bool UShockActionSetBouncerCanStepBack::RequestSet()
{
	if (BouncerLabel.IsNone()) return false;
	return true;
}
