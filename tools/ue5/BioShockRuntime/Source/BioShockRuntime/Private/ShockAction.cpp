#include "ShockAction.h"

#include "ShockVariable.h"
#include "ShockVariableScope.h"
#include "UObject/UnrealType.h"

namespace
{
	bool SetPropertyText(UObject* Target, FName PropertyName, const FString& Text)
	{
		if (!Target || PropertyName.IsNone())
		{
			return false;
		}
		FProperty* Property = Target->GetClass()->FindPropertyByName(PropertyName);
		if (!Property)
		{
			return false;
		}

		void* ValuePtr = Property->ContainerPtrToValuePtr<void>(Target);
		if (FStrProperty* StringProperty = CastField<FStrProperty>(Property))
		{
			StringProperty->SetPropertyValue(ValuePtr, Text);
			return true;
		}
		if (FNameProperty* NameProperty = CastField<FNameProperty>(Property))
		{
			NameProperty->SetPropertyValue(ValuePtr, FName(*Text));
			return true;
		}
		if (FBoolProperty* BoolProperty = CastField<FBoolProperty>(Property))
		{
			const bool bValue = Text.Equals(TEXT("1")) || Text.Equals(TEXT("True"), ESearchCase::IgnoreCase);
			BoolProperty->SetPropertyValue(ValuePtr, bValue);
			return true;
		}
		if (FNumericProperty* NumericProperty = CastField<FNumericProperty>(Property))
		{
			if (!Text.IsNumeric())
			{
				return false;
			}
			if (NumericProperty->IsFloatingPoint())
			{
				NumericProperty->SetFloatingPointPropertyValue(ValuePtr, FCString::Atod(*Text));
			}
			else
			{
				NumericProperty->SetIntPropertyValue(ValuePtr, FCString::Atoi64(*Text));
			}
			return true;
		}

		// Structs/enums and future reflected parameter types keep UE's own text import semantics.
		return Property->ImportText_Direct(*Text, ValuePtr, Target, PPF_None) != nullptr;
	}
}

void UShockAction::AddVariableResolver(FName PropertyName, FName VariableName, FName SourcePropertyName)
{
	FShockParameterResolveInfo& Info = ResolveInfoList.AddDefaulted_GetRef();
	Info.PropertyName = PropertyName;
	Info.SourceKind = EShockParameterSourceKind::Variable;
	Info.VariableName = VariableName;
	Info.SourcePropertyName = SourcePropertyName.IsNone() ? FName(TEXT("Value")) : SourcePropertyName;
}

void UShockAction::AddActionPropertyResolver(
	FName PropertyName, UShockAction* SourceAction, FName SourcePropertyName, int32 SourceActionIndex)
{
	FShockParameterResolveInfo& Info = ResolveInfoList.AddDefaulted_GetRef();
	Info.PropertyName = PropertyName;
	Info.SourceKind = EShockParameterSourceKind::ActionProp;
	Info.SourceAction = SourceAction;
	Info.SourceActionIndex = SourceActionIndex;
	Info.SourcePropertyName = SourcePropertyName.IsNone() ? FName(TEXT("Value")) : SourcePropertyName;
}

bool UShockAction::ResolveParameters(const FShockActionContext& Ctx)
{
	if (ResolveInfoList.IsEmpty())
	{
		return true;
	}
	if (bResolvingParameters)
	{
		// Malformed cyclic expression graph: fail the binding instead of recursing forever.
		return false;
	}

	bResolvingParameters = true;
	bool bAllResolved = true;
	for (const FShockParameterResolveInfo& Info : ResolveInfoList)
	{
		UShockVariable* SourceValue = nullptr;
		if (Info.SourceKind == EShockParameterSourceKind::Variable)
		{
			SourceValue = Ctx.Variables ? Ctx.Variables->Find(Info.VariableName) : nullptr;
		}
		else if (Info.SourceAction)
		{
			SourceValue = Info.SourceAction->GetReturnValue();
			if (!SourceValue)
			{
				// Resolver actions are expression nodes in shipped packages (often outered to the
				// consumer rather than present in Script.Actions). Evaluate once on first use.
				Info.SourceAction->ResolveParameters(Ctx);
				Info.SourceAction->ApplyInWorld(Ctx);
				SourceValue = Info.SourceAction->GetReturnValue();
			}
		}

		FString Text;
		if (!SourceValue || !SourceValue->GetPropertyText(Info.SourcePropertyName, Text)
			|| !SetPropertyText(this, Info.PropertyName, Text))
		{
			bAllResolved = false;
		}
	}
	bResolvingParameters = false;
	return bAllResolved;
}

void UShockAction::SetReturnValueText(const FString& Value, FName VariableClassName)
{
	if (!ReturnValue)
	{
		ReturnValue = NewObject<UShockVariable>(this);
	}
	ReturnValue->Configure(Value, VariableClassName);
}
