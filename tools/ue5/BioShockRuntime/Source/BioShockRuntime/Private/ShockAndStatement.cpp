#include "ShockAndStatement.h"

namespace
{
	bool NestedOrLiteral(const UShockAction* Owner, FName PropertyToken, bool Literal)
	{
		if (!Owner)
		{
			return Literal;
		}
		for (const FShockParameterResolveInfo& Info : Owner->ResolveInfoList)
		{
			if (!Info.PropertyName.ToString().Equals(PropertyToken.ToString(), ESearchCase::IgnoreCase))
			{
				continue;
			}
			if (const UShockActionBool* Nested = Cast<UShockActionBool>(Info.SourceAction))
			{
				return Nested->EvaluateBool();
			}
		}
		return Literal;
	}
}

UShockAndStatement::UShockAndStatement()
{
	ActionClassName = TEXT("AndStatement");
}

void UShockAndStatement::Configure(bool bInLhs, bool bInRhs)
{
	Lhs = bInLhs;
	Rhs = bInRhs;
}

bool UShockAndStatement::EvaluateBool() const
{
	return NestedOrLiteral(this, TEXT("lhs"), Lhs) && NestedOrLiteral(this, TEXT("rhs"), Rhs);
}
