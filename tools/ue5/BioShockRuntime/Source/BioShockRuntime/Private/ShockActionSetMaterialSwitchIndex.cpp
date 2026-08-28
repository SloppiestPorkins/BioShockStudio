#include "ShockActionSetMaterialSwitchIndex.h"

#include "ShockPlayer.h"

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

int32 UShockActionSetMaterialSwitchIndex::ApplyInWorld(UWorld* World)
{
	if (!RequestSet() || !World)
	{
		return 0;
	}
	AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World);
	if (!Player)
	{
		return 0;
	}
	Player->SetMaterialSwitchIndex(MaterialSwitchName, Index);
	return 1;
}
