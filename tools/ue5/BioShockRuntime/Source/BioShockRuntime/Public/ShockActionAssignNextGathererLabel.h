#pragma once

#include "ShockAction.h"
#include "ShockActionAssignNextGathererLabel.generated.h"

/** UnrealScript `ActionAssignNextGathererLabel`. Records protector + gatherer labels; no spawn yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionAssignNextGathererLabel : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionAssignNextGathererLabel();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName ProtectorLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName GathererLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastProtectorLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InProtector, FName InGatherer);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastProtectorLabel() const { return LastProtectorLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestAssign();
};
