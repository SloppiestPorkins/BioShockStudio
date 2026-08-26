#include "ShockActionTellAIToWait.h"

UShockActionTellAIToWait::UShockActionTellAIToWait()
{
	ActionClassName = TEXT("ActionTellAIToWait");
}

void UShockActionTellAIToWait::Configure(FName InAILabel)
{
	AILabel = InAILabel;
}

bool UShockActionTellAIToWait::RequestWait()
{
	if (AILabel.IsNone())
	{
		return false;
	}
	LastAILabel = AILabel;
	return true;
}
