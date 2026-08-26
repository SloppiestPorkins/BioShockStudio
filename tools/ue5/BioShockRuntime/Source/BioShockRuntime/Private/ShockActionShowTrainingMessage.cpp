#include "ShockActionShowTrainingMessage.h"

UShockActionShowTrainingMessage::UShockActionShowTrainingMessage()
{
	ActionClassName = TEXT("ActionShowTrainingMessage");
}

void UShockActionShowTrainingMessage::Configure(FName InMessageName)
{
	MessageName = InMessageName;
}

bool UShockActionShowTrainingMessage::RequestShow()
{
	if (MessageName.IsNone())
	{
		return false;
	}
	LastMessageName = MessageName;
	return true;
}
