#include "ShockTruthStatement.h"

UShockTruthStatement::UShockTruthStatement()
{
	ActionClassName = TEXT("TruthStatement");
}

void UShockTruthStatement::Configure(FName InValue)
{
	Value = InValue;
}

bool UShockTruthStatement::EvaluateBool() const
{
	if (Value.IsNone())
	{
		return false;
	}
	return FCString::ToBool(*Value.ToString());
}
