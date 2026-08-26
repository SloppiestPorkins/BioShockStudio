#include "ShockActionDisplayOnScreenDebugMessage.h"

UShockActionDisplayOnScreenDebugMessage::UShockActionDisplayOnScreenDebugMessage()
{
	ActionClassName = TEXT("ActionDisplayOnScreenDebugMessage");
	Message = TEXT("<message text>");
}

void UShockActionDisplayOnScreenDebugMessage::Configure(const FString& InMessage)
{
	Message = InMessage;
}

bool UShockActionDisplayOnScreenDebugMessage::RequestDisplay()
{
	if (Message.IsEmpty())
	{
		return false;
	}
	LastMessage = Message;
	return true;
}
