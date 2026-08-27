#include "ShockActionChangePEGWaitDistance.h"

UShockActionChangePEGWaitDistance::UShockActionChangePEGWaitDistance()
{
	ActionClassName = TEXT("ActionChangePEGWaitDistance");
}

void UShockActionChangePEGWaitDistance::Configure(FName InPEG, float InWaitDistance)
{
	PEGLabel = InPEG;
	WaitDistance = InWaitDistance;
}

bool UShockActionChangePEGWaitDistance::RequestSet()
{
	if (PEGLabel.IsNone())
	{
		return false;
	}
	LastPEGLabel = PEGLabel;
	return true;
}
