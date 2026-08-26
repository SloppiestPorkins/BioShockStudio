#include "ShockActionVariableAssign.h"

#include "ShockVariableScope.h"

UShockActionVariableAssign::UShockActionVariableAssign()
{
	ActionClassName = TEXT("ActionVariableAssign");
}

void UShockActionVariableAssign::Configure(FName InLhs, const FString& InRhs)
{
	Lhs = InLhs;
	Rhs = InRhs;
}

bool UShockActionVariableAssign::ApplyToScope(UShockVariableScope* Scope)
{
	if (Scope == nullptr || Lhs.IsNone())
	{
		return false;
	}
	if (bOnlyIfMissing && Scope->Contains(Lhs))
	{
		return false;
	}
	Scope->Set(Lhs, Rhs);
	return true;
}
