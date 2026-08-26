#include "ShockActionSetOrUnsetInputContext.h"

UShockActionSetOrUnsetInputContext::UShockActionSetOrUnsetInputContext()
{
	ActionClassName = TEXT("ActionSetOrUnsetInputContext");
}

void UShockActionSetOrUnsetInputContext::Configure(FName InContext, bool bInUnset)
{
	Context = InContext;
	bUnset = bInUnset;
}

bool UShockActionSetOrUnsetInputContext::RequestContext()
{
	if (Context.IsNone())
	{
		return false;
	}
	LastContext = Context;
	return true;
}
