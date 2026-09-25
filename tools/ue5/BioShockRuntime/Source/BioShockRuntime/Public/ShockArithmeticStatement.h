#pragma once

#include "ShockAction.h"
#include "ShockArithmeticStatement.generated.h"

/**
 * UnrealScript `ArithmeticStatement`: produces a numeric Value from lhs/rhs and
 * ARITHMETICOP_ADD/SUBTRACT/MULTIPLY/DIVIDE for nested Bindings (ch.21 / Ex.14).
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockArithmeticStatement : public UShockAction
{
	GENERATED_BODY()

public:
	UShockArithmeticStatement();

	/** 0=Add, 1=Subtract, 2=Multiply, 3=Divide (ARITHMETICOP_*). */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 ArithmeticOp = 0;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString Lhs;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString Rhs;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(int32 InOp, const FString& InLhs, const FString& InRhs);

	virtual bool ApplyInWorld(const FShockActionContext& Ctx) override;
};
