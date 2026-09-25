#pragma once

#include "ShockActionBool.h"
#include "ShockNotStatement.generated.h"

/** UnrealScript `NotStatement` (ActionBool). Binding PropertyName=rhs → UPROPERTY Rhs. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockNotStatement : public UShockActionBool
{
	GENERATED_BODY()

public:
	UShockNotStatement();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool Rhs = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(bool bInRhs);

	virtual bool EvaluateBool() const override;
};
