#include "ShockOrStatement.h"

UShockOrStatement::UShockOrStatement()
{
	ActionClassName = TEXT("OrStatement");
}

void UShockOrStatement::Configure(bool bInLhs, bool bInRhs)
{
	bLhs = bInLhs;
	bRhs = bInRhs;
}

bool UShockOrStatement::EvaluateBool() const
{
	return bLhs || bRhs;
}
