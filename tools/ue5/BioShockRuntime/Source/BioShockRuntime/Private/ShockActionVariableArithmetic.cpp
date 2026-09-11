#include "ShockActionVariableArithmetic.h"

#include "ShockVariable.h"
#include "ShockVariableScope.h"

void UShockActionVariableArithmetic::Configure(FName InLhs, const FString& InRhs)
{
	Lhs = InLhs;
	Rhs = InRhs;
}

bool UShockActionVariableArithmetic::ApplyInWorld(const FShockActionContext& Ctx)
{
	ClearReturnValue();
	UShockVariable* Left = Ctx.Variables ? Ctx.Variables->Find(Lhs) : nullptr;
	if (!Left)
	{
		return false;
	}

	if (Operation == EShockVariableArithmeticOp::Add
		&& Left->VariableClassName != FName(TEXT("VariableFloat")))
	{
		SetReturnValueText(Left->Value + Rhs, Left->VariableClassName);
		return true;
	}

	if (!Left->Value.IsNumeric() || !Rhs.IsNumeric())
	{
		// UE2 VariableString/Name/Bool leave subtract/multiply/divide unchanged.
		SetReturnValueText(Left->Value, Left->VariableClassName);
		return true;
	}

	const double A = FCString::Atod(*Left->Value);
	const double B = FCString::Atod(*Rhs);
	double Result = A;
	switch (Operation)
	{
	case EShockVariableArithmeticOp::Add: Result = A + B; break;
	case EShockVariableArithmeticOp::Subtract: Result = A - B; break;
	case EShockVariableArithmeticOp::Multiply: Result = A * B; break;
	case EShockVariableArithmeticOp::Divide:
		if (FMath::IsNearlyZero(B))
		{
			return false;
		}
		Result = A / B;
		break;
	}
	SetReturnValueText(LexToString(Result), TEXT("VariableFloat"));
	return true;
}

UShockActionVariableAdd::UShockActionVariableAdd()
{
	ActionClassName = TEXT("ActionVariableAdd");
	Operation = EShockVariableArithmeticOp::Add;
}

UShockActionVariableSubtract::UShockActionVariableSubtract()
{
	ActionClassName = TEXT("ActionVariableSubtract");
	Operation = EShockVariableArithmeticOp::Subtract;
}

UShockActionVariableMultiply::UShockActionVariableMultiply()
{
	ActionClassName = TEXT("ActionVariableMultiply");
	Operation = EShockVariableArithmeticOp::Multiply;
}

UShockActionVariableDivide::UShockActionVariableDivide()
{
	ActionClassName = TEXT("ActionVariableDivide");
	Operation = EShockVariableArithmeticOp::Divide;
}
