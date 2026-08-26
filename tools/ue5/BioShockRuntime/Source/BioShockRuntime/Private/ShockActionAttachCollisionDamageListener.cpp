#include "ShockActionAttachCollisionDamageListener.h"

UShockActionAttachCollisionDamageListener::UShockActionAttachCollisionDamageListener()
{
	ActionClassName = TEXT("ActionAttachCollisionDamageListener");
}

void UShockActionAttachCollisionDamageListener::Configure(FName InTarget, FName InOwner)
{
	TargetLabel = InTarget;
	OwnerLabel = InOwner;
}

bool UShockActionAttachCollisionDamageListener::RequestAttach()
{
	if (TargetLabel.IsNone() || OwnerLabel.IsNone())
	{
		return false;
	}
	LastTargetLabel = TargetLabel;
	return true;
}
