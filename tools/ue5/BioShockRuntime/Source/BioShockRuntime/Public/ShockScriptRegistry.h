#pragma once

#include "UObject/Object.h"
#include "ShockScriptRegistry.generated.h"

class UShockScriptRunner;

/** UHT cannot nest a TArray as a TMap value, so the per-label runner list is a struct. */
USTRUCT()
struct FShockRunnerList
{
	GENERATED_BODY()

	UPROPERTY()
	TArray<TObjectPtr<UShockScriptRunner>> Runners;
};

/**
 * Label → script runner lookup for ExecuteScript + message dispatch.
 * Medical ships at least one duplicate Script label (StandingOnCremationBody ×2), so the
 * registry keeps every runner that registers under a label (TArray per FName), not a single slot.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockScriptRegistry : public UObject
{
	GENERATED_BODY()

public:
	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	void RegisterScript(UShockScriptRunner* Script);

	/** First runner registered under Label (ExecuteScript / StopTimer convenience). */
	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	UShockScriptRunner* FindScript(FName Label) const;

	/** Every runner whose ScriptLabel equals Label (FName compare is case-insensitive). */
	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	TArray<UShockScriptRunner*> FindAllScripts(FName Label) const;

	/** Every registered runner across all labels (level-travel critical flush). */
	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	TArray<UShockScriptRunner*> GetAllRunners() const;

	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	int32 Num() const;

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
	TMap<FName, FShockRunnerList> ByLabel;
};
