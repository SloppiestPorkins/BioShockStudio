#pragma once

#include "ShockAction.h"
#include "ShockActionVariableArithmetic.generated.h"

class UShockVariableScope;

UENUM()
enum class EShockVariableArithmeticOp : uint8
{
	Add,
	Subtract,
	Multiply,
	Divide,
};

/** Shared implementation for ActionVariableAdd/Subtract/Multiply/Divide expression actions. */
UCLASS(Abstract)
class BIOSHOCKRUNTIME_API UShockActionVariableArithmetic : public UShockAction
{
	GENERATED_BODY()

public:
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName Lhs;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString Rhs;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InLhs, const FString& InRhs);

	virtual bool ApplyInWorld(const FShockActionContext& Ctx) override;

protected:
	EShockVariableArithmeticOp Operation = EShockVariableArithmeticOp::Add;
};

UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionVariableAdd : public UShockActionVariableArithmetic
{
	GENERATED_BODY()
public:
	UShockActionVariableAdd();
};

UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionVariableSubtract : public UShockActionVariableArithmetic
{
	GENERATED_BODY()
public:
	UShockActionVariableSubtract();
};

UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionVariableMultiply : public UShockActionVariableArithmetic
{
	GENERATED_BODY()
public:
	UShockActionVariableMultiply();
};

UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionVariableDivide : public UShockActionVariableArithmetic
{
	GENERATED_BODY()
public:
	UShockActionVariableDivide();
};
