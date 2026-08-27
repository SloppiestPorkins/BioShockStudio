#pragma once

#include "ShockAction.h"
#include "ShockActionKeypadContainerUsed.generated.h"

UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionKeypadContainerUsed : public UShockAction
{
	GENERATED_BODY()
public:
	UShockActionKeypadContainerUsed();
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName KeypadContainerLabel;
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bSuccess = false;
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InLabel, bool bInSuccess);
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestNotify();
};
