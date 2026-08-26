#pragma once

#include "ShockAction.h"
#include "ShockActionDisableOrEnableConcept.generated.h"

UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionDisableOrEnableConcept : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionDisableOrEnableConcept();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName ConceptName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bEnable = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastConceptName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bLastEnable = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InConceptName, bool bInEnable);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastConceptName() const { return LastConceptName; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetLastEnable() const { return bLastEnable; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestToggle();
};
