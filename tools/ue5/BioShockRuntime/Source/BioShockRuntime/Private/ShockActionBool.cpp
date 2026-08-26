#include "ShockActionBool.h"

UShockActionBool::UShockActionBool()
{
	ActionClassName = TEXT("ActionBool");
}

bool UShockActionBool::EvaluateBool() const
{
	return false;
}
