#include "ShockActionAssignNextGathererBooty.h"

UShockActionAssignNextGathererBooty::UShockActionAssignNextGathererBooty()
{
	ActionClassName = TEXT("ActionAssignNextGathererBooty");
}

void UShockActionAssignNextGathererBooty::Configure(FName InBooty, FName InGatherer)
{
	NextGathererBootyLabel = InBooty;
	GathererLabel = InGatherer;
}

bool UShockActionAssignNextGathererBooty::RequestAssign()
{
	if (GathererLabel.IsNone())
	{
		return false;
	}
	LastGathererLabel = GathererLabel;
	return true;
}
