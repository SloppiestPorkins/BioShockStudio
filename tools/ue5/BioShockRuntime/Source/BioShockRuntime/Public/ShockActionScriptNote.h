#pragma once

#include "ShockActionBool.h"
#include "ShockActionScriptNote.generated.h"

/**
 * UnrealScript `ActionScriptNote`: editor-only note string; execute does nothing at runtime.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionScriptNote : public UShockActionBool
{
	GENERATED_BODY()

public:
	UShockActionScriptNote();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString Note;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(const FString& InNote);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FString GetNote() const { return Note; }

	virtual bool EvaluateBool() const override;
};
