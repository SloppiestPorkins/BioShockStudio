#pragma once

#include "ShockAction.h"
#include "ShockActionAssignNextGathererBooty.generated.h"

/** UnrealScript `ActionAssignNextGathererBooty`. Booty object stored as FName label. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionAssignNextGathererBooty : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionAssignNextGathererBooty();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName NextGathererBootyLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName GathererLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastGathererLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InBooty, FName InGatherer);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastGathererLabel() const { return LastGathererLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestAssign();
};
