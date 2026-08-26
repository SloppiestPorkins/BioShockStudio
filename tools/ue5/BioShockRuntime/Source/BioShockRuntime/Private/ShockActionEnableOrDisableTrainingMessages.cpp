#include "ShockActionEnableOrDisableTrainingMessages.h"

UShockActionEnableOrDisableTrainingMessages::UShockActionEnableOrDisableTrainingMessages()
{
	ActionClassName = TEXT("ActionEnableOrDisableTrainingMessages");
}

void UShockActionEnableOrDisableTrainingMessages::Configure(bool bInEnable)
{
	bEnableTrainingMessages = bInEnable;
}

bool UShockActionEnableOrDisableTrainingMessages::RequestSet()
{
	bLastEnableTrainingMessages = bEnableTrainingMessages;
	return true;
}
