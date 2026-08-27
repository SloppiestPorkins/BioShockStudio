#pragma once

#include "ShockAction.h"
#include "ShockActionEnableOrDisableSoundPropagation.generated.h"

UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionEnableOrDisableSoundPropagation : public UShockAction
{
	GENERATED_BODY()
public:
	UShockActionEnableOrDisableSoundPropagation();
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bEnable = true;
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(bool bInEnable);
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetEnable() const { return bEnable; }
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSet();
};
