#pragma once

#include "ShockActionBool.h"
#include "ShockOrStatement.generated.h"

/** UnrealScript `OrStatement` (ActionBool). Bindings PropertyName=lhs|rhs → UPROPERTY Lhs/Rhs. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockOrStatement : public UShockActionBool
{
	GENERATED_BODY()

public:
	UShockOrStatement();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool Lhs = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool Rhs = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(bool bInLhs, bool bInRhs);

	virtual bool EvaluateBool() const override;
};
