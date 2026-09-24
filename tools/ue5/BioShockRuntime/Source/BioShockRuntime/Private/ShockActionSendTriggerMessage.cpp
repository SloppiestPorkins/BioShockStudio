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
	// UE2's base "Message" class -- confirmed against the shipped UnrealEd guide: a script with
	// scriptMessageClass=Message "accepts every message from the listed labels", the pattern
	// movers and generic trigger relays are built on. Not yet checked receiver-side (see
	// docs/research/message-class-gap.md) but the dispatched name should be the real one.
	LastDispatchAccepted = InRegistry->DispatchMessage(FName(TEXT("Message")), Source.ToString());
	return LastDispatchAccepted;
}
