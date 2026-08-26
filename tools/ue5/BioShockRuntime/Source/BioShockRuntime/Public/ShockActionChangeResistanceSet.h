#pragma once

#include "ShockAction.h"
#include "ShockActionChangeResistanceSet.generated.h"

/** UnrealScript `ActionChangeResistanceSet`. Records Target + set name; no resistance swap yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionChangeResistanceSet : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionChangeResistanceSet();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName Target;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName ResistanceSetName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastResistanceSetName;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InTarget, FName InSet);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetResistanceSetName() const { return ResistanceSetName; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastResistanceSetName() const { return LastResistanceSetName; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestChange();
};
