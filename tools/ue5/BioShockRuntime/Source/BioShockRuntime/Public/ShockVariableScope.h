#pragma once

#include "UObject/Object.h"
#include "ShockVariableScope.generated.h"

/** Minimal stand-in for Scripting.Variable storage on a Script actor. String values only. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockVariableScope : public UObject
{
	GENERATED_BODY()

public:
	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	bool Contains(FName Name) const;

	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	bool TryGet(FName Name, FString& OutValue) const;

	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	FString GetValueOrEmpty(FName Name) const;

	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	void Set(FName Name, const FString& Value);

	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	int32 Num() const { return Values.Num(); }

private:
	UPROPERTY()
	TMap<FName, FString> Values;
};
