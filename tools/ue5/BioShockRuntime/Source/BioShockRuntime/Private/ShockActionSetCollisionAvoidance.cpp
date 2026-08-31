#include "ShockActionSetCollisionAvoidance.h"

#include "BaseShockAI.h"

UShockActionSetCollisionAvoidance::UShockActionSetCollisionAvoidance()
{
	ActionClassName = TEXT("ActionSetCollisionAvoidance");
}

void UShockActionSetCollisionAvoidance::Configure(FName InAILabel, bool bInUse)
{
	AILabel = InAILabel;
	bShouldUseCollisionAvoidance = bInUse;
}

bool UShockActionSetCollisionAvoidance::RequestSet()
{
	if (AILabel.IsNone())
	{
		return false;
	}
	LastAILabel = AILabel;
	return true;
}

int32 UShockActionSetCollisionAvoidance::ApplyInWorld(UWorld* World)
{
	if (!RequestSet())
	{
		return 0;
	}
	int32 Applied = 0;
	for (ABaseShockAI* AI : ABaseShockAI::CollectLabeled(World, AILabel))
	{
		AI->SetCollisionAvoidanceEnabled(bShouldUseCollisionAvoidance);
		++Applied;
	}
	return Applied;
}

bool UShockActionSetCollisionAvoidance::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World) > 0;
}
