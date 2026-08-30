#pragma once

#include "ShockActionBool.h"
#include "ShockOrStatement.generated.h"

/** UnrealScript `OrStatement` (ActionBool). First slice: bool Lhs || Rhs (no Variable VM). */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockOrStatement : public UShockActionBool
{
	GENERATED_BODY()

public:
	UShockOrStatement();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bLhs = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bRhs = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(bool bInLhs, bool bInRhs);

	virtual bool EvaluateBool() const override;
};
