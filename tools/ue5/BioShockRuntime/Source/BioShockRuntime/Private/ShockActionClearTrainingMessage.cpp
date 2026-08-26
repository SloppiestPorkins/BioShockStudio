#include "ShockActionClearTrainingMessage.h"

UShockActionClearTrainingMessage::UShockActionClearTrainingMessage()
{
	ActionClassName = TEXT("ActionClearTrainingMessage");
}

void UShockActionClearTrainingMessage::Configure(FName InMessage)
{
	MessageName = InMessage;
}

bool UShockActionClearTrainingMessage::RequestClear()
{
	if (MessageName.IsNone())
	{
		return false;
	}
	LastMessageName = MessageName;
	return true;
}
