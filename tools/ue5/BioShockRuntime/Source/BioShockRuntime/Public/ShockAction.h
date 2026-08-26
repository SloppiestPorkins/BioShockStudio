#pragma once

#include "UObject/Object.h"
#include "ShockAction.generated.h"

/**
 * UnrealScript `Action` parameter block. No Execute — Phase 4 implements behaviour from the
 * decompiled .uc, most-used first. This object exists so a script graph has something to point at.
 */
UCLASS()
class BIOSHOCKRUNTIME_API UShockAction : public UObject
{
	GENERATED_BODY()

public:
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString ActionClassName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	TMap<FString, FString> Parameters;
};
