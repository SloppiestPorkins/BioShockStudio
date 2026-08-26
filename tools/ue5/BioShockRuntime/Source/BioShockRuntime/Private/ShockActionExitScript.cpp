#include "ShockActionExitScript.h"

UShockActionExitScript::UShockActionExitScript()
{
	ActionClassName = TEXT("ActionExitScript");
}

void UShockActionExitScript::Configure(FName InTargetScript)
{
	TargetScript = InTargetScript;
}

bool UShockActionExitScript::RequestExit()
{
	LastExitedScript = TargetScript.IsNone() ? FName(TEXT("Current")) : TargetScript;
	return true;
}
