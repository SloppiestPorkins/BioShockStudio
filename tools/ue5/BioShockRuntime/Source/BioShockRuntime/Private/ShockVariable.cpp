#include "ShockVariable.h"

#include "UObject/UnrealType.h"

void UShockVariable::Configure(const FString& InValue, FName InVariableClassName)
{
	Value = InValue;
	VariableClassName = InVariableClassName.IsNone() ? InferVariableClass(InValue) : InVariableClassName;
}

bool UShockVariable::GetPropertyText(FName PropertyName, FString& OutValue) const
{
	if (PropertyName.IsNone() || PropertyName == GET_MEMBER_NAME_CHECKED(UShockVariable, Value))
	{
		OutValue = Value;
		return true;
	}

	const FProperty* Property = GetClass()->FindPropertyByName(PropertyName);
	if (!Property)
	{
		return false;
	}
	const void* ValuePtr = Property->ContainerPtrToValuePtr<void>(this);
	Property->ExportTextItem_Direct(OutValue, ValuePtr, nullptr, const_cast<UShockVariable*>(this), PPF_None);
	return true;
}

FName UShockVariable::InferVariableClass(const FString& Text)
{
	if (Text.Equals(TEXT("True"), ESearchCase::IgnoreCase)
		|| Text.Equals(TEXT("False"), ESearchCase::IgnoreCase))
	{
		return TEXT("VariableBool");
	}
	if (Text.IsNumeric())
	{
		return TEXT("VariableFloat");
	}
	return TEXT("VariableString");
}
