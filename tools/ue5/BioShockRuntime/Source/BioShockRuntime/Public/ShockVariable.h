#pragma once

#include "UObject/Object.h"
#include "ShockVariable.generated.h"

/**
 * Runtime value returned by a Scripting.Action or stored in a Script variable scope.
 *
 * UE2 used VariableFloat/VariableString/VariableName/VariableBool subclasses whose common
 * contract was a property named Value. The port retains the class identity as metadata while
 * storing the serialized value text centrally; resolveInfoList can therefore perform the same
 * named-property transfer without losing the source type.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockVariable : public UObject
{
	GENERATED_BODY()

public:
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Script")
	FString Value;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Script")
	FName VariableClassName = TEXT("VariableString");

	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	void Configure(const FString& InValue, FName InVariableClassName);

	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	FString GetValue() const { return Value; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	FName GetVariableClassName() const { return VariableClassName; }

	/** Export a named property as text; ParameterResolveInfo action sources normally request Value. */
	bool GetPropertyText(FName PropertyName, FString& OutValue) const;

	static FName InferVariableClass(const FString& Text);
};
