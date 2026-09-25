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

	/**
	 * DispatchMessage carrying the message's own fields (UE2 Message subclass properties such as
	 * PawnLabel / PawnClass / ActualClass / Instigator), so a script's messageFilter can be
	 * evaluated against them. A field the sender does not supply cannot rule a script out.
	 */
	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	int32 DispatchMessageWithFields(
		FName MessageClassName, const FString& SourceLabel, const TMap<FString, FString>& Fields);

private:
	UPROPERTY()
	TMap<FName, TObjectPtr<UShockScriptRunner>> ByLabel;
};
