#pragma once

#include "ShockPawn.h"
#include "BaseShockAI.generated.h"

/** UnrealScript `BaseShockAI`. No states, no actions — the class exists so AI work has a home. */
UCLASS()
class BIOSHOCKRUNTIME_API ABaseShockAI : public AShockPawn
{
	GENERATED_BODY()

public:
	ABaseShockAI();
};
