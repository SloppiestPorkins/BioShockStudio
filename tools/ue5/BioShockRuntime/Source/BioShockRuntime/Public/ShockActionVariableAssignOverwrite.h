#pragma once

#include "ShockActionVariableAssign.h"
#include "ShockActionVariableAssignOverwrite.generated.h"

/**
 * UnrealScript `ActionVariableAssign` — overwrite assign into a variable scope.
 * Class name in C++ avoids clashing with the abstract shared base `UShockActionVariableAssign`.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionVariableAssignOverwrite : public UShockActionVariableAssign
{
	GENERATED_BODY()

public:
	UShockActionVariableAssignOverwrite();
};
