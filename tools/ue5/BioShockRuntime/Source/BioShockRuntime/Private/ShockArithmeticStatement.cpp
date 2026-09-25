#include "ShockArithmeticStatement.h"

#include "ShockVariable.h"

UShockArithmeticStatement::UShockArithmeticStatement()
{
	ActionClassName = TEXT("ArithmeticStatement");
}

void UShockArithmeticStatement::Configure(int32 InOp, const FString& InLhs, const FString& InRhs)
{
	ArithmeticOp = InOp;
	Lhs = InLhs;
	Rhs = InRhs;
}

bool UShockArithmeticStatement::ApplyInWorld(const FShockActionContext& Ctx)
{
	(void)Ctx;
	ClearReturnValue();
	const double Left = Lhs.IsNumeric() ? FCString::Atod(*Lhs) : 0.0;
	const double Right = Rhs.IsNumeric() ? FCString::Atod(*Rhs) : 0.0;
	double Result = 0.0;
	switch (ArithmeticOp)
	{
	case 0: Result = Left + Right; break;
	case 1: Result = Left - Right; break;
	case 2: Result = Left * Right; break;
	case 3: Result = FMath::IsNearlyZero(Right) ? 0.0 : (Left / Right); break;
	default: Result = 0.0; break;
	}
	SetReturnValueText(LexToString(Result), TEXT("VariableFloat"));
	return true;
}
