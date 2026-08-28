#include "ShockActionChangePawnPhysics.h"

#include "ShockPawn.h"

UShockActionChangePawnPhysics::UShockActionChangePawnPhysics()
{
	ActionClassName = TEXT("ActionChangePawnPhysics");
}

void UShockActionChangePawnPhysics::Configure(FName InTarget, bool bInDisable, bool bInRootMotion)
{
	TargetLabel = InTarget;
	bDisablePhysics = bInDisable;
	bEnableRootMotionWhenPhysicsDisabled = bInRootMotion;
}

bool UShockActionChangePawnPhysics::RequestChange()
{
	if (TargetLabel.IsNone())
	{
		return false;
	}
	LastTargetLabel = TargetLabel;
	return true;
}

int32 UShockActionChangePawnPhysics::ApplyInWorld(UWorld* World)
{
	if (!RequestChange())
	{
		return 0;
	}
	int32 Applied = 0;
	for (AShockPawn* Pawn : AShockPawn::CollectLabeled(World, TargetLabel))
	{
		Pawn->SetScriptedPhysicsDisabled(bDisablePhysics, bEnableRootMotionWhenPhysicsDisabled);
		++Applied;
	}
	return Applied;
}
