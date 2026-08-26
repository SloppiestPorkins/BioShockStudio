#include "ShockActionVariableIncrement.h"

#include "ShockVariableScope.h"

UShockActionVariableIncrement::UShockActionVariableIncrement()
{
	ActionClassName = TEXT("ActionVariableIncrement");
}

void UShockActionVariableIncrement::Configure(FName InTarget)
{
	Target = InTarget;
}

bool UShockActionVariableIncrement::ApplyToScope(UShockVariableScope* Scope)
{
	if (Scope == nullptr || Target.IsNone())
	{
		return false;
	}
	FString Current;
	int32 Value = 0;
	if (Scope->TryGet(Target, Current) && !Current.IsEmpty())
	{
		LexFromString(Value, *Current);
	}
	Scope->Set(Target, FString::FromInt(Value + 1));
	return true;
}
