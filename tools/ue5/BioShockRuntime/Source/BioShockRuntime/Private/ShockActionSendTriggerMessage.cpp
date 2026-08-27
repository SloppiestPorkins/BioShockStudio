#include "ShockActionSendTriggerMessage.h"

#include "ShockScriptRegistry.h"

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

int32 UShockActionSendTriggerMessage::DispatchVia(UShockScriptRegistry* InRegistry, FName ParentScriptLabel)
{
	const FName Source = InstigatorLabel.IsNone() ? ParentScriptLabel : InstigatorLabel;
	LastInstigatorLabel = Source;
	LastDispatchAccepted = 0;
	if (InRegistry == nullptr || Source.IsNone())
	{
		return 0;
	}
	LastDispatchAccepted = InRegistry->DispatchMessage(FName(TEXT("MessageTrigger")), Source.ToString());
	return LastDispatchAccepted;
}
