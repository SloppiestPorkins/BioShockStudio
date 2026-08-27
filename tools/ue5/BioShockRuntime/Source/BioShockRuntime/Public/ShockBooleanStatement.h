#pragma once

#include "ShockActionBool.h"
#include "ShockBooleanStatement.generated.h"

/** UnrealScript `BooleanStatement` (ActionBool). Compare lhs/rhs with logicOp; no Variable VM yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockBooleanStatement : public UShockActionBool
{
	GENERATED_BODY()

public:
	UShockBooleanStatement();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 LogicOp = 2;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString Lhs;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString Rhs;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(int32 InLogicOp, const FString& InLhs, const FString& InRhs);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 GetLogicOp() const { return LogicOp; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool TestEvaluate() const { return EvaluateBool(); }

	virtual bool EvaluateBool() const override;
};
