#include "ShockActionAttachToBone.h"

UShockActionAttachToBone::UShockActionAttachToBone()
{
	ActionClassName = TEXT("ActionAttachToBone");
}

void UShockActionAttachToBone::Configure(
	FName InAttachment,
	FName InBase,
	FName InBone,
	FVector InRelativeLocation,
	FRotator InRelativeRotation)
{
	AttachmentActorLabel = InAttachment;
	BaseActorLabel = InBase;
	TargetBone = InBone;
	AttachmentRelativeLocation = InRelativeLocation;
	AttachmentRelativeRotation = InRelativeRotation;
}

bool UShockActionAttachToBone::RequestAttach()
{
	if (AttachmentActorLabel.IsNone() || BaseActorLabel.IsNone())
	{
		return false;
	}
	LastAttachmentActorLabel = AttachmentActorLabel;
	return true;
}
