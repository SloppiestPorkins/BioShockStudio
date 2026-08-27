#pragma once

#include "ShockActionBool.h"
#include "ShockAndStatement.generated.h"

/** UnrealScript `AndStatement` (ActionBool). First slice: bool Lhs && Rhs (no Variable VM). */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockAndStatement : public UShockActionBool
{
	GENERATED_BODY()

public:
	UShockAndStatement();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bLhs = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bRhs = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(bool bInLhs, bool bInRhs);

	virtual bool EvaluateBool() const override;
};
