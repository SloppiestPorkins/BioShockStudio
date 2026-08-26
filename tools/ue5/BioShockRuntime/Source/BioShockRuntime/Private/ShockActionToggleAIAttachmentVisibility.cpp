#include "ShockActionToggleAIAttachmentVisibility.h"

UShockActionToggleAIAttachmentVisibility::UShockActionToggleAIAttachmentVisibility()
{
	ActionClassName = TEXT("ActionToggleAIAttachmentVisibility");
}

void UShockActionToggleAIAttachmentVisibility::Configure(FName InAILabel, FName InCategory, bool bInHide)
{
	AILabel = InAILabel;
	AttachmentCategory = InCategory;
	bHideAttachments = bInHide;
}

bool UShockActionToggleAIAttachmentVisibility::RequestToggle()
{
	if (AILabel.IsNone())
	{
		return false;
	}
	LastAILabel = AILabel;
	return true;
}
