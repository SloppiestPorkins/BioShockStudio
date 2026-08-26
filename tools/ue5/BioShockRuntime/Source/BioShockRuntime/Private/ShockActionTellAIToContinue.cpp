#include "ShockActionTellAIToContinue.h"

UShockActionTellAIToContinue::UShockActionTellAIToContinue()
{
	ActionClassName = TEXT("ActionTellAIToContinue");
}

void UShockActionTellAIToContinue::Configure(FName InAILabel)
{
	AILabel = InAILabel;
}

bool UShockActionTellAIToContinue::RequestContinue()
{
	if (AILabel.IsNone())
	{
		return false;
	}
	LastAILabel = AILabel;
	return true;
}
