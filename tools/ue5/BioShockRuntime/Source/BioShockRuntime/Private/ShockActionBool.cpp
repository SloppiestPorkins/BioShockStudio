#include "ShockActionBool.h"

#include "ShockVariable.h"

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

bool UShockActionBool::ApplyInWorld(const FShockActionContext& Ctx)
{
	const bool bResult = EvaluateInWorld(Ctx.World);
	SetReturnValueText(bResult ? TEXT("True") : TEXT("False"), TEXT("VariableBool"));
	return true;
}
