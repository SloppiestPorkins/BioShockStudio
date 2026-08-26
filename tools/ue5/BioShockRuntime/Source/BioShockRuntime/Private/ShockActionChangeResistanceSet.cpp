#include "ShockActionChangeResistanceSet.h"

UShockActionChangeResistanceSet::UShockActionChangeResistanceSet()
{
	ActionClassName = TEXT("ActionChangeResistanceSet");
	ResistanceSetName = FName(TEXT("Default"));
}

void UShockActionChangeResistanceSet::Configure(FName InTarget, FName InSet)
{
	Target = InTarget;
	ResistanceSetName = InSet;
}

bool UShockActionChangeResistanceSet::RequestChange()
{
	if (Target.IsNone() || ResistanceSetName.IsNone())
	{
		return false;
	}
	LastResistanceSetName = ResistanceSetName;
	return true;
}
