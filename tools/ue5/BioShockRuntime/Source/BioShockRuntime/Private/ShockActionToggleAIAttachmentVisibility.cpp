#include "ShockActionToggleAIAttachmentVisibility.h"

#include "BaseShockAI.h"

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

int32 UShockActionToggleAIAttachmentVisibility::ApplyInWorld(UWorld* World)
{
	if (!RequestToggle())
	{
		return 0;
	}
	int32 Applied = 0;
	for (ABaseShockAI* AI : ABaseShockAI::CollectLabeled(World, AILabel))
	{
		AI->SetAttachmentCategoryHidden(AttachmentCategory, bHideAttachments);
		++Applied;
	}
	return Applied;
}

bool UShockActionToggleAIAttachmentVisibility::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World) > 0;
}
