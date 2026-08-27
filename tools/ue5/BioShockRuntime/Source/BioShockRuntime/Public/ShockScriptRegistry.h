#pragma once

#include "UObject/Object.h"
#include "ShockScriptRegistry.generated.h"

class UShockScriptRunner;

/** Label → script runner lookup for ExecuteScript + message dispatch. First-slice; not level actors. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockScriptRegistry : public UObject
{
	GENERATED_BODY()

public:
	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	void RegisterScript(UShockScriptRunner* Script);

	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	UShockScriptRunner* FindScript(FName Label) const;

	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	int32 Num() const { return ByLabel.Num(); }

	/**
	 * Start or queue every registered script whose TriggeredBy matches SourceLabel.
	 * Returns how many accepted the message (started or queued). Scripts that reject
	 * (disabled / TriggeredBy mismatch) are not counted.
	 */
	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	int32 DispatchMessage(FName MessageClassName, const FString& SourceLabel);

private:
	UPROPERTY()
	TMap<FName, TObjectPtr<UShockScriptRunner>> ByLabel;
};
