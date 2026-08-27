#pragma once

#include "ShockAction.h"
#include "ShockActionFor.generated.h"

/**
 * UnrealScript `ActionFor` (Scripting.U). Counter loop over forActions.
 * Holds counter bounds + nested ForActions; runner expands the body once per enter
 * (full counter VariableFloat iterations still open).
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionFor : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionFor();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName CounterName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float BeginValue = 0.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float EndValue = 0.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 CurrentIndex = -1;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bEnteredFor = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	TArray<TObjectPtr<UShockAction>> ForActions;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InCounter, float InBegin, float InEnd, int32 InIndex);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void AddForAction(UShockAction* Action);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 GetForActionNum() const { return ForActions.Num(); }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetCounterName() const { return CounterName; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 GetCurrentIndex() const { return CurrentIndex; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetEnteredFor() const { return bEnteredFor; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestEnterFor();
};
