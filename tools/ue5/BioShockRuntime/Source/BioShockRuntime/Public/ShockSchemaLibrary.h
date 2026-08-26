#pragma once

#include "Kismet/BlueprintFunctionLibrary.h"
#include "ShockSchemaLibrary.generated.h"

class AActor;

/**
 * Applies Phase 2.1 class-schema JSON onto a spawned actor.
 *
 * Inheritance is walked inside the JSON (leaf overrides parent). Properties that are not in
 * ShockGame.U — standing CollisionHeight lives on Engine.U's VPawn — are not invented.
 */
UCLASS()
class BIOSHOCKRUNTIME_API UShockSchemaLibrary : public UBlueprintFunctionLibrary
{
	GENERATED_BODY()

public:
	UFUNCTION(BlueprintCallable, Category="BioShock|Runtime")
	static FString ApplyClassDefaults(AActor* Actor, const FString& SchemaJsonPath, const FString& ClassName);
};
