#include "ShockActionEnableOrDisableHavokForceActor.h"

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
