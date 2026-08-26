#include "ShockVariableScope.h"

bool UShockVariableScope::Contains(FName Name) const
{
	return Values.Contains(Name);
}

bool UShockVariableScope::TryGet(FName Name, FString& OutValue) const
{
	if (const FString* Found = Values.Find(Name))
	{
		OutValue = *Found;
		return true;
	}
	return false;
}

FString UShockVariableScope::GetValueOrEmpty(FName Name) const
{
	if (const FString* Found = Values.Find(Name))
	{
		return *Found;
	}
	return FString();
}

void UShockVariableScope::Set(FName Name, const FString& Value)
{
	Values.Add(Name, Value);
}
