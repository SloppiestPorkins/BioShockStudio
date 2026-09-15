#include "ShockActionSetEffectsSystemContext.h"

#include "ShockEffectsSubsystem.h"

UShockActionSetEffectsSystemContext::UShockActionSetEffectsSystemContext()
{
	ActionClassName = TEXT("ActionSetEffectsSystemContext");
	Context = FName(TEXT("ONE_WORD_THAT_DESCRIBES_THE_NEW_CONTEXT"));
}

void UShockActionSetEffectsSystemContext::Configure(
	FName InContext,
	uint8 InAppliesTo,
	bool bInRemove,
	bool bInLog)
{
	Context = InContext;
	ContextAppliesTo = InAppliesTo;
	bRemoveInsteadOfAdd = bInRemove;
	bLogTriggerInfo = bInLog;
}

bool UShockActionSetEffectsSystemContext::RequestSet()
{
	if (Context.IsNone() || Context == FName(TEXT("ONE_WORD_THAT_DESCRIBES_THE_NEW_CONTEXT")))
	{
		return false;
	}
	LastContext = Context;
	return true;
}

bool UShockActionSetEffectsSystemContext::ApplyInWorld(UWorld* World)
{
	if (!RequestSet())
	{
		return false;
	}
	UShockEffectsSubsystem* Fx = UShockEffectsSubsystem::Get(World);
	if (!Fx)
	{
		return false;
	}
	if (bRemoveInsteadOfAdd)
	{
		Fx->RemoveContext(Context);
	}
	else
	{
		Fx->PushContext(Context);
	}
	return true;
}

bool UShockActionSetEffectsSystemContext::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World);
}
