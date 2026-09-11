#pragma once

#include "UObject/Object.h"
#include "ShockVariableScope.generated.h"

class UShockVariable;

/** Scripting.Variable storage for a Script actor, with compatibility string accessors. */
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

	/** The real Variable object used by Action.resolveInfoList. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	UShockVariable* Find(FName Name) const;

	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	int32 Num() const { return Values.Num(); }

private:
	UPROPERTY()
	TMap<FName, TObjectPtr<UShockVariable>> Values;
};
