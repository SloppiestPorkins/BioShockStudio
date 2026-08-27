#pragma once

#include "ShockAction.h"
#include "ShockActionSetGrenadierSuicideState.generated.h"

/** UnrealScript `ActionSetGrenadierSuicideState`. Records grenadier + suicide enum. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionSetGrenadierSuicideState : public UShockAction
{
	GENERATED_BODY()
public:
	UShockActionSetGrenadierSuicideState();
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName GrenadierLabel;
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 SpecialCommitSuicideState = 0;
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastGrenadierLabel;
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InLabel, int32 InState);
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSet();
};
