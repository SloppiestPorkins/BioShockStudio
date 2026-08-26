#include "ShockActionRemoveScriptedHandAttachment.h"

UShockActionRemoveScriptedHandAttachment::UShockActionRemoveScriptedHandAttachment()
{
	ActionClassName = TEXT("ActionRemoveScriptedHandAttachment");
}

bool UShockActionRemoveScriptedHandAttachment::RequestRemove()
{
	bRemoveRequested = true;
	return true;
}
