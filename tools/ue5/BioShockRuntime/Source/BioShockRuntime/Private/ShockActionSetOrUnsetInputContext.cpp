#include "ShockActionSetOrUnsetInputContext.h"

#include "ShockPlayer.h"

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

int32 UShockActionSetOrUnsetInputContext::ApplyInWorld(UWorld* World)
{
	if (!RequestContext())
	{
		return 0;
	}
	AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World);
	if (!Player)
	{
		return 0;
	}
	Player->SetInputContext(Context, bUnset);
	return 1;
}
