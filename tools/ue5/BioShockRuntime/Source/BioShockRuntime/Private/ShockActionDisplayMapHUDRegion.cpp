#include "ShockActionDisplayMapHUDRegion.h"

UShockActionDisplayMapHUDRegion::UShockActionDisplayMapHUDRegion()
{
	ActionClassName = TEXT("ActionDisplayMapHUDRegion");
}

void UShockActionDisplayMapHUDRegion::Configure(const FString& InDescription)
{
	MapHUDRegionDescription = InDescription;
}

bool UShockActionDisplayMapHUDRegion::RequestDisplay()
{
	bRequested = true;
	return true;
}
