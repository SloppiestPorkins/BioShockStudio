#include "ShockActionWaitUntilActorHasLanded.h"

UShockActionWaitUntilActorHasLanded::UShockActionWaitUntilActorHasLanded()
{
	ActionClassName = TEXT("ActionWaitUntilActorHasLanded");
	TargetLabel = FName(TEXT("UNSPECIFIED"));
}

void UShockActionWaitUntilActorHasLanded::Configure(FName InTarget)
{
	TargetLabel = InTarget;
}

bool UShockActionWaitUntilActorHasLanded::RequestWait()
{
	if (TargetLabel.IsNone() || TargetLabel == FName(TEXT("UNSPECIFIED")))
	{
		return false;
	}
	LastTargetLabel = TargetLabel;
	return true;
}
