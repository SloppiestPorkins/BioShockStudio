#pragma once

#include "ShockActionExecuteScript.h"
#include "ShockActionBlockingExecuteScript.generated.h"

/** UnrealScript `ActionBlockingExecuteScript` — ActionExecuteScript with block=true. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionBlockingExecuteScript : public UShockActionExecuteScript
{
	GENERATED_BODY()

public:
	UShockActionBlockingExecuteScript();
};
