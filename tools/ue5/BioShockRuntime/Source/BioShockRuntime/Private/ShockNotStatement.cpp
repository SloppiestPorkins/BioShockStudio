#include "ShockNotStatement.h"

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

UShockNotStatement::UShockNotStatement()
{
	ActionClassName = TEXT("NotStatement");
}

void UShockNotStatement::Configure(bool bInRhs)
{
	Rhs = bInRhs;
}

bool UShockNotStatement::EvaluateBool() const
{
	return !NestedOrLiteral(this, TEXT("rhs"), Rhs);
}
