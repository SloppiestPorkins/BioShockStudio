#include "ShockBooleanStatement.h"

UShockBooleanStatement::UShockBooleanStatement()
{
	ActionClassName = TEXT("BooleanStatement");
	LogicOp = 2;
}

void UShockBooleanStatement::Configure(int32 InLogicOp, const FString& InLhs, const FString& InRhs)
{
	LogicOp = InLogicOp;
	Lhs = InLhs;
	Rhs = InRhs;
}

bool UShockBooleanStatement::EvaluateBool() const
{
	if (Lhs.IsNumeric() && Rhs.IsNumeric())
	{
		const double Left = FCString::Atod(*Lhs);
		const double Right = FCString::Atod(*Rhs);
		switch (LogicOp)
		{
		case 0: return Left < Right;
		case 1: return Left <= Right;
		case 2: return FMath::IsNearlyEqual(Left, Right);
		case 3: return !FMath::IsNearlyEqual(Left, Right);
		case 4: return Left >= Right;
		case 5: return Left > Right;
		default: return false;
		}
	}
	switch (LogicOp)
	{
	case 0: return Lhs < Rhs;
	case 1: return Lhs <= Rhs;
	case 2: return Lhs == Rhs;
	case 3: return Lhs != Rhs;
	case 4: return Lhs >= Rhs;
	case 5: return Lhs > Rhs;
	default: return false;
	}
}
