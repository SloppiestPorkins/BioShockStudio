#include "ShockActionExecuteScript.h"

UShockActionExecuteScript::UShockActionExecuteScript()
{
	ActionClassName = TEXT("ActionExecuteScript");
}

void UShockActionExecuteScript::Configure(FName InTargetScript, bool bInBlock)
{
	TargetScript = InTargetScript;
	bBlock = bInBlock;
}

bool UShockActionExecuteScript::RequestExecute()
{
	if (TargetScript.IsNone())
	{
		return false;
	}
	LastRequestedScript = TargetScript;
	bLastRequestWasBlocking = bBlock;
	return true;
}
