#include "ShockActionEnableOrDisableHavokForceActor.h"

#include "ShockPhysicsLibrary.h"

UShockActionEnableOrDisableHavokForceActor::UShockActionEnableOrDisableHavokForceActor()
{
	ActionClassName = TEXT("ActionEnableOrDisableHavokForceActor");
}

void UShockActionEnableOrDisableHavokForceActor::Configure(FName InTarget, bool bInEnabled)
{
	Target = InTarget;
	bEnabled = bInEnabled;
}

bool UShockActionEnableOrDisableHavokForceActor::RequestSet()
{
	if (Target.IsNone())
	{
		return false;
	}
	LastTarget = Target;
	return true;
}

int32 UShockActionEnableOrDisableHavokForceActor::ApplyInWorld(UWorld* World)
{
	if (!RequestSet() || !World)
	{
		return 0;
	}
	UShockPhysicsLibrary::SetHavokForceActorEnabled(Target, bEnabled);
	return 1;
}
