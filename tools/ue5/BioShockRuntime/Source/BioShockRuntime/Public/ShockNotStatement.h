#pragma once

#include "ShockActionBool.h"
#include "ShockNotStatement.generated.h"

/** UnrealScript `NotStatement` (ActionBool). First slice: !Rhs (no Variable VM). */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockNotStatement : public UShockActionBool
{
	GENERATED_BODY()

public:
	UShockNotStatement();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bRhs = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(bool bInRhs);

	virtual bool EvaluateBool() const override;
};
