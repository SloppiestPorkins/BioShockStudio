#pragma once

#include "Kismet/BlueprintFunctionLibrary.h"
#include "ShockSchemaLibrary.generated.h"

class AActor;
class UShockAction;

/**
 * Applies Phase 2.1 class-schema JSON onto a spawned actor or action.
 *
 * Inheritance is walked inside the JSON (leaf overrides parent). Standing CollisionHeight is
 * declared on VPawn in VengeanceShared.U, so the schema JSON must include that class (or the
 * inherited float on a ShockGame parent) — it is not invented here.
 */
UCLASS()
class BIOSHOCKRUNTIME_API UShockSchemaLibrary : public UBlueprintFunctionLibrary
{
	GENERATED_BODY()

public:
	UFUNCTION(BlueprintCallable, Category="BioShock|Runtime")
	static FString ApplyClassDefaults(AActor* Actor, const FString& SchemaJsonPath, const FString& ClassName);

	UFUNCTION(BlueprintCallable, Category="BioShock|Runtime")
	static FString ApplyActionDefaults(UShockAction* Action, const FString& SchemaJsonPath, const FString& ClassName);
};
