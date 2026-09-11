#include "ShockActionGetMessageValue.h"

#include "ShockVariable.h"

UShockActionGetMessageValue::UShockActionGetMessageValue()
{
	ActionClassName = TEXT("ActionGetMessageValue");
}

void UShockActionGetMessageValue::Configure(FName InPropertyName)
{
	Property = InPropertyName;
}

bool UShockActionGetMessageValue::ApplyInWorld(const FShockActionContext& Ctx)
{
	ClearReturnValue();
	FString Text;
	const FString RequestedProperty = Property.ToString();
	if (RequestedProperty.Equals(TEXT("Source"), ESearchCase::IgnoreCase)
		|| RequestedProperty.Equals(TEXT("SourceLabel"), ESearchCase::IgnoreCase))
	{
		Text = Ctx.MessageSource;
	}
	else if (RequestedProperty.Equals(TEXT("Class"), ESearchCase::IgnoreCase)
		|| RequestedProperty.Equals(TEXT("ClassName"), ESearchCase::IgnoreCase)
		|| RequestedProperty.Equals(TEXT("MessageClass"), ESearchCase::IgnoreCase))
	{
		Text = Ctx.MessageClass.ToString();
	}
	else
	{
		return false;
	}
	SetReturnValueText(Text, UShockVariable::InferVariableClass(Text));
	return true;
}
