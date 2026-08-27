#include "ShockActionBool.h"

UShockActionBool::UShockActionBool()
{
	ActionClassName = TEXT("ActionBool");
}

bool UShockActionBool::EvaluateBool() const
{
	return false;
}

bool UShockActionBool::EvaluateInWorld(UWorld* World) const
{
	(void)World;
	return EvaluateBool();
}
