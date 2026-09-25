#pragma once

#include "ShockAction.h"
#include "ShockActionGetLevelLabel.generated.h"

/** UnrealScript `ActionGetLevelLabel`: returns the map file name lower-cased. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionGetLevelLabel : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionGetLevelLabel();

	virtual bool ApplyInWorld(const FShockActionContext& Ctx) override;
};
