#include "ShockActionSetTipPriority.h"

UShockActionSetTipPriority::UShockActionSetTipPriority()
{
	ActionClassName = TEXT("ActionSetTipPriority");
}

void UShockActionSetTipPriority::Configure(FName InTipName, int32 InPriority)
{
	TipName = InTipName;
	Priority = InPriority;
}

bool UShockActionSetTipPriority::RequestSet()
{
	if (TipName.IsNone())
	{
		return false;
	}
	LastTipName = TipName;
	LastPriority = Priority;
	return true;
}
