#include "ShockActionSetCorpseCanBeRemoved.h"

UShockActionSetCorpseCanBeRemoved::UShockActionSetCorpseCanBeRemoved()
{
	ActionClassName = TEXT("ActionSetCorpseCanBeRemoved");
}

void UShockActionSetCorpseCanBeRemoved::Configure(FName InCorpse, bool bInCanRemove)
{
	CorpseLabel = InCorpse;
	bCorpseCanBeRemoved = bInCanRemove;
}

bool UShockActionSetCorpseCanBeRemoved::RequestSet()
{
	if (CorpseLabel.IsNone())
	{
		return false;
	}
	LastCorpseLabel = CorpseLabel;
	return true;
}
