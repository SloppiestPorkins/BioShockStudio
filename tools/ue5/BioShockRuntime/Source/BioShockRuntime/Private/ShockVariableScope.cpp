#include "ShockVariableScope.h"

#include "ShockVariable.h"

bool UShockVariableScope::Contains(FName Name) const
{
	return Values.Contains(Name);
}

bool UShockVariableScope::TryGet(FName Name, FString& OutValue) const
{
	if (const TObjectPtr<UShockVariable>* Found = Values.Find(Name); Found && *Found)
	{
		OutValue = (*Found)->Value;
		return true;
	}
	return false;
}

FString UShockVariableScope::GetValueOrEmpty(FName Name) const
{
	if (const TObjectPtr<UShockVariable>* Found = Values.Find(Name); Found && *Found)
	{
		return (*Found)->Value;
	}
	return FString();
}

void UShockVariableScope::Set(FName Name, const FString& Value)
{
	if (TObjectPtr<UShockVariable>* Existing = Values.Find(Name); Existing && *Existing)
	{
		(*Existing)->Value = Value;
		return;
	}
	UShockVariable* Variable = NewObject<UShockVariable>(this);
	Variable->Configure(Value, UShockVariable::InferVariableClass(Value));
	Values.Add(Name, Variable);
}

UShockVariable* UShockVariableScope::Find(FName Name) const
{
	if (const TObjectPtr<UShockVariable>* Found = Values.Find(Name))
	{
		return Found->Get();
	}
	return nullptr;
}
