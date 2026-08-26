#pragma once

#include "ShockActionExecuteScript.h"
#include "ShockActionNonBlockingExecuteScript.generated.h"

/** UnrealScript `ActionNonBlockingExecuteScript` — ActionExecuteScript with block=false. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionNonBlockingExecuteScript : public UShockActionExecuteScript
{
	GENERATED_BODY()

public:
	UShockActionNonBlockingExecuteScript();
};
