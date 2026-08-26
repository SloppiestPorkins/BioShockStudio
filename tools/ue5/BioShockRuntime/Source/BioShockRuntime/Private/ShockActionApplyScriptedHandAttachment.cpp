#include "ShockActionApplyScriptedHandAttachment.h"

UShockActionApplyScriptedHandAttachment::UShockActionApplyScriptedHandAttachment()
{
	ActionClassName = TEXT("ActionApplyScriptedHandAttachment");
}

void UShockActionApplyScriptedHandAttachment::Configure(FName InClass, FName InBone)
{
	AttachmentClass = InClass;
	AttachmentBone = InBone;
}

bool UShockActionApplyScriptedHandAttachment::RequestApply()
{
	if (AttachmentClass.IsNone())
	{
		return false;
	}
	LastAttachmentClass = AttachmentClass;
	return true;
}
