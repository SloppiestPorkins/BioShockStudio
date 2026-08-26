#include "ShockActionChangeSkinAtIndex.h"

UShockActionChangeSkinAtIndex::UShockActionChangeSkinAtIndex()
{
	ActionClassName = TEXT("ActionChangeSkinAtIndex");
	TargetLabel = TEXT("UNSPECIFIED");
}

void UShockActionChangeSkinAtIndex::Configure(FName InTarget, FName InMaterial, int32 InIndex)
{
	TargetLabel = InTarget;
	MaterialName = InMaterial;
	Index = InIndex;
}

bool UShockActionChangeSkinAtIndex::RequestChangeSkin()
{
	if (TargetLabel.IsNone() || TargetLabel == FName(TEXT("UNSPECIFIED")))
	{
		return false;
	}
	LastTargetLabel = TargetLabel;
	LastIndex = Index;
	return true;
}
