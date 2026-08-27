#pragma once

#include "ShockAction.h"
#include "ShockActionDisableOrEnableMachine.generated.h"

UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionDisableOrEnableMachine : public UShockAction
{
	GENERATED_BODY()
public:
	UShockActionDisableOrEnableMachine();
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName MachineLabel;
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName MachineClassName;
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bEnable = true;
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InLabel, FName InClass, bool bInEnable);
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSet();
};
