#pragma once

#include "ShockAction.h"
#include "ShockActionRemoveCraftingFormula.generated.h"

/** UnrealScript `ActionRemoveCraftingFormula`. Records FormulaClass; no U-Invent yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionRemoveCraftingFormula : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionRemoveCraftingFormula();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName FormulaClass;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastFormulaClass;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InFormula);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastFormulaClass() const { return LastFormulaClass; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestRemove();
};
