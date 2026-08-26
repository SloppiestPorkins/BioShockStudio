#include "ShockActionSetEffectsSystemContext.h"

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
