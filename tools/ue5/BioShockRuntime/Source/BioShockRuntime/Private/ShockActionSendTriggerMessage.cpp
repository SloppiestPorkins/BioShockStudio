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
	// The SDK guide (21-Scripting-Logic-and-Variables, ActionSendTriggerMessage; 20 message
	// tables): MessageTrigger goes out under the RUNNING SCRIPT's own label -- that is what a
	// mover or another script lists in TriggeredBy -- and Instigator is only a field carried in
	// the message (empty = the script's own label, or Player). The previous code made the
	// Instigator the dispatch source, so a mover listening for the script never heard it, and used
	// class "Message" (found by the SDK cross-reference audit, docs/research/sdk-crossref-scripting.md
	// SCR-B01/B02).
	const FName Instigator = InstigatorLabel.IsNone() ? ParentScriptLabel : InstigatorLabel;
	LastInstigatorLabel = Instigator;
	LastDispatchAccepted = 0;
	if (InRegistry == nullptr || ParentScriptLabel.IsNone())
	{
		return 0;
	}
	TMap<FString, FString> Fields;
	Fields.Add(TEXT("Instigator"), Instigator.ToString());
	LastDispatchAccepted = InRegistry->DispatchMessageWithFields(
		FName(TEXT("MessageTrigger")), ParentScriptLabel.ToString(), Fields);
	return LastDispatchAccepted;
}
