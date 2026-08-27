#include "ShockActionKeypadContainerUsed.h"

UShockActionKeypadContainerUsed::UShockActionKeypadContainerUsed()
{
	ActionClassName = TEXT("ActionKeypadContainerUsed");
}
void UShockActionKeypadContainerUsed::Configure(FName InLabel, bool bInSuccess)
{
	KeypadContainerLabel = InLabel;
	bSuccess = bInSuccess;
}
bool UShockActionKeypadContainerUsed::RequestNotify()
{
	if (KeypadContainerLabel.IsNone()) return false;
	return true;
}
