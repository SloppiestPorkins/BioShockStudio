#include "ShockBooleanStatement.h"

namespace
{
	enum class EShockBoolCompareKind : uint8
	{
		Boolean,
		Number,
		NameOrString,
	};

	bool LooksLikeNameToken(const FString& Text)
	{
		if (Text.IsEmpty())
		{
			return false;
		}
		for (TCHAR Ch : Text)
		{
			const bool bOk = FChar::IsAlpha(Ch) || FChar::IsDigit(Ch) || Ch == TEXT('_') || Ch == TEXT('-');
			if (!bOk)
			{
				return false;
			}
		}
		return true;
	}

	EShockBoolCompareKind InferCompareKind(const FString& LhsText)
	{
		if (LhsText.Equals(TEXT("True"), ESearchCase::IgnoreCase)
			|| LhsText.Equals(TEXT("False"), ESearchCase::IgnoreCase))
		{
			return EShockBoolCompareKind::Boolean;
		}
		// Digits / '-' / '.' only, or empty — numeric (empty rhs/lhs coerces as 0).
		if (LhsText.IsEmpty() || LhsText.IsNumeric())
		{
			return EShockBoolCompareKind::Number;
		}
		if (LooksLikeNameToken(LhsText))
		{
			return EShockBoolCompareKind::NameOrString;
		}
		return EShockBoolCompareKind::NameOrString;
	}

	bool AsBoolText(const FString& Text)
	{
		return Text.Equals(TEXT("True"), ESearchCase::IgnoreCase)
			|| Text.Equals(TEXT("1"));
	}

	double AsNumberOrZero(const FString& Text)
	{
		return Text.IsNumeric() ? FCString::Atod(*Text) : 0.0;
	}
}

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
	const EShockBoolCompareKind Kind = InferCompareKind(Lhs);
	switch (Kind)
	{
	case EShockBoolCompareKind::Boolean:
	{
		const bool Left = AsBoolText(Lhs);
		const bool Right = AsBoolText(Rhs);
		switch (LogicOp)
		{
		case 2: return Left == Right;
		case 3: return Left != Right;
		default: return false; // ordered ops on bool are always false
		}
	}
	case EShockBoolCompareKind::Number:
	{
		const double Left = AsNumberOrZero(Lhs);
		const double Right = AsNumberOrZero(Rhs);
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
	case EShockBoolCompareKind::NameOrString:
	default:
	{
		switch (LogicOp)
		{
		case 2: return Lhs.Equals(Rhs, ESearchCase::IgnoreCase);
		case 3: return !Lhs.Equals(Rhs, ESearchCase::IgnoreCase);
		default: return false; // ordered ops on name/string are always false
		}
	}
	}
}
