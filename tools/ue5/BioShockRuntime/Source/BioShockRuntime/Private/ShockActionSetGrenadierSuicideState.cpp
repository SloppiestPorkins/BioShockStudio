#include "ShockActionSetGrenadierSuicideState.h"

UShockActionSetGrenadierSuicideState::UShockActionSetGrenadierSuicideState()
{
	ActionClassName = TEXT("ActionSetGrenadierSuicideState");
}
void UShockActionSetGrenadierSuicideState::Configure(FName InLabel, int32 InState)
{
	GrenadierLabel = InLabel;
	SpecialCommitSuicideState = InState;
}
bool UShockActionSetGrenadierSuicideState::RequestSet()
{
	if (GrenadierLabel.IsNone()) return false;
	LastGrenadierLabel = GrenadierLabel;
	return true;
}
