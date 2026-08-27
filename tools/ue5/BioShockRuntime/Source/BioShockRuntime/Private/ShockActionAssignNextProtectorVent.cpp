#include "ShockActionAssignNextProtectorVent.h"

UShockActionAssignNextProtectorVent::UShockActionAssignNextProtectorVent()
{
	ActionClassName = TEXT("ActionAssignNextProtectorVent");
}
void UShockActionAssignNextProtectorVent::Configure(FName InVent, FName InProtector)
{
	NextProtectorVentName = InVent;
	ProtectorLabel = InProtector;
}
bool UShockActionAssignNextProtectorVent::RequestAssign()
{
	if (NextProtectorVentName.IsNone() || ProtectorLabel.IsNone()) return false;
	return true;
}
