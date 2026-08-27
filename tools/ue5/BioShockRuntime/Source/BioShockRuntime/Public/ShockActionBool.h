#pragma once

#include "ShockAction.h"
#include "ShockActionBool.generated.h"

/** UnrealScript `ActionBool`. Subclasses return a boolean for ActionIf's testsOr OR. */
UCLASS(Abstract, BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionBool : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionBool();

	/** Used by ActionIf's testsOr OR. Not Blueprint-exposed — subclasses override in C++. */
	virtual bool EvaluateBool() const;

	/** World-aware evaluation (e.g. ActionPropertyTest by actor Label). Defaults to EvaluateBool. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	virtual bool EvaluateInWorld(class UWorld* World) const;
};
