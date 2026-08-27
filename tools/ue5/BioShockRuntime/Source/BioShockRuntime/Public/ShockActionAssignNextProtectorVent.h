#pragma once

#include "ShockAction.h"
#include "ShockActionAssignNextProtectorVent.generated.h"

UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionAssignNextProtectorVent : public UShockAction
{
	GENERATED_BODY()
public:
	UShockActionAssignNextProtectorVent();
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName NextProtectorVentName;
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName ProtectorLabel;
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InVent, FName InProtector);
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestAssign();
};
