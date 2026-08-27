#include "ShockNotStatement.h"

UShockNotStatement::UShockNotStatement()
{
	ActionClassName = TEXT("NotStatement");
}

void UShockNotStatement::Configure(bool bInRhs)
{
	bRhs = bInRhs;
}

bool UShockNotStatement::EvaluateBool() const
{
	return !bRhs;
}
