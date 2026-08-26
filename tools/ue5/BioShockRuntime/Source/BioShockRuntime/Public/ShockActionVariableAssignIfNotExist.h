#pragma once

#include "ShockActionVariableAssign.h"
#include "ShockActionVariableAssignIfNotExist.generated.h"

/** UnrealScript `ActionVariableAssignIfNotExist` — assign only when lhs is missing. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionVariableAssignIfNotExist : public UShockActionVariableAssign
{
	GENERATED_BODY()

public:
	UShockActionVariableAssignIfNotExist();
};
