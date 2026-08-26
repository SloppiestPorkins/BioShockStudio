#include "ShockActionAssignNextGathererLabel.h"

UShockActionAssignNextGathererLabel::UShockActionAssignNextGathererLabel()
{
	ActionClassName = TEXT("ActionAssignNextGathererLabel");
}

void UShockActionAssignNextGathererLabel::Configure(FName InProtector, FName InGatherer)
{
	ProtectorLabel = InProtector;
	GathererLabel = InGatherer;
}

bool UShockActionAssignNextGathererLabel::RequestAssign()
{
	if (ProtectorLabel.IsNone() || GathererLabel.IsNone())
	{
		return false;
	}
	LastProtectorLabel = ProtectorLabel;
	return true;
}
