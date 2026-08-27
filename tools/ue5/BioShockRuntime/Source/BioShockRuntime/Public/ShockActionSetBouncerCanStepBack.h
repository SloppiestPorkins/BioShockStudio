#pragma once

#include "ShockAction.h"
#include "ShockActionSetBouncerCanStepBack.generated.h"

UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionSetBouncerCanStepBack : public UShockAction
{
	GENERATED_BODY()
public:
	UShockActionSetBouncerCanStepBack();
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName BouncerLabel;
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bCanStepBack = true;
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InLabel, bool bInCanStepBack);
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSet();
};
