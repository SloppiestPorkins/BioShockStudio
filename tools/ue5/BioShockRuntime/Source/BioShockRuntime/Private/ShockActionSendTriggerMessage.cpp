#include "ShockActionSendTriggerMessage.h"

UShockActionSendTriggerMessage::UShockActionSendTriggerMessage()
{
	ActionClassName = TEXT("ActionSendTriggerMessage");
}

void UShockActionSendTriggerMessage::Configure(FName InInstigator)
{
	InstigatorLabel = InInstigator;
}

bool UShockActionSendTriggerMessage::RequestSend()
{
	LastInstigatorLabel = InstigatorLabel;
	return true;
}
