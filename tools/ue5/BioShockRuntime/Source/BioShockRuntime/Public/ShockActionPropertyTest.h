#pragma once

#include "ShockActionBool.h"
#include "ShockActionPropertyTest.generated.h"

class UWorld;

/**
 * UnrealScript `ActionPropertyTest` (Scripting.U, native). Compare actor property to Value.
 * Label / ActorLabel path evaluates in-world; other propertyPaths stay false until wired.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionPropertyTest : public UShockActionBool
{
	GENERATED_BODY()

public:
	UShockActionPropertyTest();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName Label;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString PropertyPath;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString Value;

	/** EOpTest: 0 Less … 5 Greater (default Equals=2). */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 OpTest = 2;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 MaxPasses = -1;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InLabel, const FString& InPropertyPath, const FString& InValue, int32 InOpTest, int32 InMaxPasses);

	virtual bool EvaluateBool() const override;
	virtual bool EvaluateInWorld(UWorld* World) const override;
};
