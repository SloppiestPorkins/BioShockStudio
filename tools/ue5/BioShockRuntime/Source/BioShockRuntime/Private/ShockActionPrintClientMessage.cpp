#include "ShockActionPrintClientMessage.h"

UShockActionPrintClientMessage::UShockActionPrintClientMessage()
{
	ActionClassName = TEXT("ActionPrintClientMessage");
}
void UShockActionPrintClientMessage::Configure(const FString& InText, FName InType)
{
	MessageText = InText;
	MessageType = InType;
}
bool UShockActionPrintClientMessage::RequestPrint()
{
	if (MessageText.IsEmpty())
	{
		return false;
	}
	LastPrintedText = MessageText;
	return true;
}
