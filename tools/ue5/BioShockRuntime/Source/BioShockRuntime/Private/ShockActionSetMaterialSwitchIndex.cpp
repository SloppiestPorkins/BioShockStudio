#include "ShockActionSetMaterialSwitchIndex.h"

UShockActionSetMaterialSwitchIndex::UShockActionSetMaterialSwitchIndex()
{
	ActionClassName = TEXT("ActionSetMaterialSwitchIndex");
}

void UShockActionSetMaterialSwitchIndex::Configure(FName InMaterial, float InIndex)
{
	MaterialSwitchName = InMaterial;
	Index = InIndex;
}

bool UShockActionSetMaterialSwitchIndex::RequestSet()
{
	if (MaterialSwitchName.IsNone())
	{
		return false;
	}
	LastIndex = Index;
	return true;
}
