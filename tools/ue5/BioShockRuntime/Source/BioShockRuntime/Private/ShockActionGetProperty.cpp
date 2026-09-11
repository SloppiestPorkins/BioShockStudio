#include "ShockActionGetProperty.h"

#include "ShockScriptReflection.h"
#include "ShockVariable.h"

UShockActionGetProperty::UShockActionGetProperty()
{
	ActionClassName = TEXT("ActionGetProperty");
}

void UShockActionGetProperty::Configure(FName InObjectLabel, const FString& InPropertyPath)
{
	ObjectLabel = InObjectLabel;
	PropertyPath = InPropertyPath;
}

bool UShockActionGetProperty::ApplyInWorld(UWorld* World)
{
	ClearReturnValue();
	AActor* Target = ShockScriptReflection::ResolveTargetActor(World, ObjectLabel);
	if (!Target)
	{
		UE_LOG(LogTemp, Warning, TEXT("BIOSHOCK_GETPROP target=%s not found"), *ObjectLabel.ToString());
		return false;
	}

	FString Value;
	const bool bOk = ShockScriptReflection::GetPropertyAsText(Target, PropertyPath, Value);
	if (bOk)
	{
		SetReturnValueText(Value, UShockVariable::InferVariableClass(Value));
	}
	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_GETPROP target=%s prop=%s value=%s ok=%d"),
		*ObjectLabel.ToString(),
		*PropertyPath,
		*Value,
		bOk ? 1 : 0);
	return bOk;
}

bool UShockActionGetProperty::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World);
}
