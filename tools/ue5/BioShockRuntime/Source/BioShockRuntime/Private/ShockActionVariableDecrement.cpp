#include "ShockActionVariableDecrement.h"

#include "ShockVariableScope.h"

UShockActionVariableDecrement::UShockActionVariableDecrement()
{
	ActionClassName = TEXT("ActionVariableDecrement");
}

void UShockActionVariableDecrement::Configure(FName InTarget)
{
	Target = InTarget;
}

bool UShockActionVariableDecrement::ApplyToScope(UShockVariableScope* Scope)
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
	Scope->Set(Target, FString::FromInt(Value - 1));
	return true;
}
