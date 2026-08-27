#include "ShockActionDisableOrEnableMachine.h"

UShockActionDisableOrEnableMachine::UShockActionDisableOrEnableMachine()
{
	ActionClassName = TEXT("ActionDisableOrEnableMachine");
}
void UShockActionDisableOrEnableMachine::Configure(FName InLabel, FName InClass, bool bInEnable)
{
	MachineLabel = InLabel;
	MachineClassName = InClass;
	bEnable = bInEnable;
}
bool UShockActionDisableOrEnableMachine::RequestSet()
{
	return true;
}
