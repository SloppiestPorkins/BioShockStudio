#include "ShockAndStatement.h"

UShockAndStatement::UShockAndStatement()
{
	ActionClassName = TEXT("AndStatement");
}

void UShockAndStatement::Configure(bool bInLhs, bool bInRhs)
{
	bLhs = bInLhs;
	bRhs = bInRhs;
}

bool UShockAndStatement::EvaluateBool() const
{
	return bLhs && bRhs;
}
