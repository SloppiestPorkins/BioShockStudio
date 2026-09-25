#pragma once

#include "ShockActionBool.h"
#include "ShockAndStatement.generated.h"

/**
 * UnrealScript `AndStatement` (ActionBool). Bindings use PropertyName=lhs|rhs; the UPROPERTY
 * names must match those tokens (FName is case-insensitive) so ResolveParameters can land.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockAndStatement : public UShockActionBool
{
	GENERATED_BODY()

public:
	UShockAndStatement();

	/** Bound as `lhs` from resolveInfoList (nested ActionBool / literal). */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool Lhs = false;

	/** Bound as `rhs` from resolveInfoList. */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool Rhs = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(bool bInLhs, bool bInRhs);

	virtual bool EvaluateBool() const override;
};
